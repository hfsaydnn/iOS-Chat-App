//
//  CBZChatFriendsViewModel.swift
//  ChatApp
//
//  Created by Mayil Kannan on 22/07/21.
//

import SwiftUI
import FirebaseFirestore

let kFriendsRequestNotificationName = NSNotification.Name(rawValue: "kFriendsRequestNotificationName")
let kFriendsUpdateNotificationName = NSNotification.Name(rawValue: "kFriendsUpdateNotificationName")

class CBZChatFriendsViewModel: ObservableObject {
    let reportingManager = ATCFirebaseUserReporter()
    @Published var friends: [ATCUser] = []
    var tempFriends: [ATCUser] = []
    @Published var filteredInBoundUsers: [ATCUser] = []
    @Published var outBoundUsers: [ATCUser] = []
    @Published var friendships: [ATCChatFriendship] = []
    var tempFriendships: [ATCChatFriendship] = []
    @Published var isUsersFetching: Bool = false {
        didSet {
            if showLoaderCount == 0 && isUsersFetching {
                showLoader = true
                showLoaderCount += 1
            } else if showLoader && !isUsersFetching {
                showLoader = false
            }
            
            if !isUsersFetching {
                self.updatingTime = Date()
            }
        }
    }
    @Published var isAllUsersFetching: Bool = false
    let userManager = ATCSocialFirebaseUserManager()
    var allUsers: [ATCUser] = []
    var filteredOutBoundAllUsers: [ATCUser] = []
    @Published var filteredAllUsers: [ATCUser] = []
    let socialManager = ATCFirebaseSocialGraphManager()
    @Published var showLoader: Bool = false
    @Published var showLoaderCount = 0
    @Published var updatingTime: Date = Date()
    var isFriendsListUpdated: Bool = false
    var isFollowersFollowingEnabled: Bool = false
    var showFollowers: Bool = false
    var loggedInUser: ATCUser? = nil
    @Published var loggedInInBoundUsers: [ATCUser] = []
    @Published var loggedInOutBoundUsers: [ATCUser] = []
    @Published var followTextUpdatingTime: Date = Date()
    var showUsersWithOutFollowers = false

    var friendsStatusSignalListener: ListenerRegistration?
    var friendsScreenUpdateNeeded: Bool = false
    var allUsersScreenUpdateNeeded: Bool = false
    
    var isFromChatHome: Bool = false
    private var isHomeFriendsUpdateAvailable: Bool = false
    var isChatHomeVisible: Bool = false {
        didSet {
            if isChatHomeVisible && isHomeFriendsUpdateAvailable {
                self.isHomeFriendsUpdateAvailable = false
                self.isUsersFetching = false
                self.friends = tempFriends
            }
        }
    }
    
    var isFromChatFriends: Bool = false
    private var isChatFriendsUpdateAvailable: Bool = false
    var isChatFriendsVisible: Bool = false {
        didSet {
            if isChatFriendsVisible && isChatFriendsUpdateAvailable {
                self.isChatFriendsUpdateAvailable = false
                self.isUsersFetching = false
                self.friendships = tempFriendships
            }
        }
    }

    init(isFollowersFollowingEnabled: Bool = false, showFollowers: Bool = false, loggedInUser: ATCUser? = nil, showUsersWithOutFollowers: Bool = false, isFromChatHome: Bool = false, isFromChatFriends: Bool = false) {
        self.isFollowersFollowingEnabled = isFollowersFollowingEnabled
        self.showFollowers = showFollowers
        self.loggedInUser = loggedInUser
        self.showUsersWithOutFollowers = showUsersWithOutFollowers
        self.isFromChatHome = isFromChatHome
        self.isFromChatFriends = isFromChatFriends
        if isFromChatHome || isFromChatFriends {
            startOnAppearDBFetches()
        }
        if isFromChatHome {
            NotificationCenter.default.addObserver(self, selector: #selector(self.friendsUpdateNotification(notification:)), name: kFriendsUpdateNotificationName, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.friendsRequestNotification(notification:)), name: kFriendsRequestNotificationName, object: nil)
    }
    
    @objc func friendsRequestNotification(notification: Notification) {
        if !showUsersWithOutFollowers {
            self.fetchFriendships(viewer: loggedInUser)
        }
    }
    
    @objc func friendsUpdateNotification(notification: Notification) {
        self.fetchFriends()
    }
    
    private func startOnAppearDBFetches() {
        guard let loggedInUser = loggedInUser, let uid = loggedInUser.uid else { return }

        if isFromChatHome {
            self.fetchFriends()
        } else {
            self.fetchFriendships(viewer: self.loggedInUser)
        }

        let reference = Firestore.firestore().collection("friendships")
            .whereField("user2", isEqualTo: uid)

        friendsStatusSignalListener = reference.addSnapshotListener { [weak self] querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            guard let `self` = self else { return }

            snapshot.documentChanges.forEach { change in
                if self.isFromChatHome {
                    self.fetchFriends()
                } else {
                    self.fetchFriendships(viewer: self.loggedInUser)
                }
            }
        }
    }
    
    func fetchAllUsers(viewer: ATCUser?) {
        guard let viewer = viewer else { return }
        isAllUsersFetching = true

        self.filteredOutBoundAllUsers.removeAll()
        self.filteredAllUsers.removeAll()
        self.fetchUsers(viewer: viewer) { (fetchAllUsers) in
            self.fetchFriendships(viewer: viewer) {
                self.isAllUsersFetching = false
                self.allUsers = fetchAllUsers
                self.filteredOutBoundAllUsers = self.allUsers.filter({ (otherUser) -> Bool in
                    !self.friendships.contains(where: { (friendship) -> Bool in
                        return ((friendship.currentUser.uid == viewer.uid && friendship.otherUser.uid == otherUser.uid) ||
                            (friendship.otherUser.uid == viewer.uid && friendship.currentUser.uid == otherUser.uid))
                    })
                })
                self.filteredAllUsers = self.filteredOutBoundAllUsers
            }
        }
    }
    
    private func fetchUsers(viewer: ATCUser, completion: @escaping (_ friends: [ATCUser]) -> Void) {
        reportingManager.userIDsBlockedOrReported(by: viewer) { (illegalUserIDsSet) in
            let usersRef = Firestore.firestore().collection("users")
            usersRef.getDocuments { (querySnapshot, error) in
                if error != nil {
                    completion([])
                    return
                }
                guard let querySnapshot = querySnapshot else {
                    completion([])
                    return
                }
                var users: [ATCUser] = []
                let documents = querySnapshot.documents
                for document in documents {
                    let data = document.data()
                    let user = ATCUser(representation: data)
                    if let userID = user.uid {
                        if userID != viewer.uid && !illegalUserIDsSet.contains(userID) {
                            users.append(user)
                        }
                    }
                }
                completion(users)
            }
        }
    }
    
    func fetchFriends() {
        guard let viewer = loggedInUser else { return }
        isUsersFetching = true
        
        self.socialManager.fetchFriends(viewer: viewer) { (friends) in
            if self.isChatHomeVisible {
                self.isHomeFriendsUpdateAvailable = false
                self.isUsersFetching = false
                self.friends = friends
            } else {
                self.isHomeFriendsUpdateAvailable = true
                self.tempFriends = friends
            }
        }
    }
    
    func fetchFriendships(viewer: ATCUser?, completion: @escaping () -> Void = { }) {
        guard let viewer = viewer else { return }
        isUsersFetching = true
        
        self.socialManager.fetchFriendships(viewer: viewer) { (friends) in
            if self.isChatFriendsVisible || self.allUsersScreenUpdateNeeded {
                self.isChatFriendsUpdateAvailable = false
                self.isUsersFetching = false
                self.friendships = friends
                completion()
            } else {
                self.isChatFriendsUpdateAvailable = true
                self.tempFriendships = friends
            }
        }
    }
    
    func addFriendRequest(fromUser: ATCUser?, toUser: ATCUser) {
        guard let fromUser = fromUser else { return }

        socialManager.sendFriendRequest(viewer: fromUser, to: toUser) {
            NotificationCenter.default.post(name: kFriendsRequestNotificationName, object: nil, userInfo: nil)
        }
        
        self.filteredOutBoundAllUsers = self.filteredOutBoundAllUsers.filter({ $0 != toUser })
        self.filteredAllUsers = self.filteredAllUsers.filter({ $0 != toUser })
        
        let message = "\(fromUser.fullName()) " + "sent you a friend request".localizedChat
        let notificationSender = ATCPushNotificationSender()
        if let token = toUser.pushToken, toUser.uid != fromUser.uid {
            notificationSender.sendPushNotification(to: token, title: "iMessenger", body: message)
        }
    }
    
    func acceptFriendRequest(fromUser: ATCUser?, toUser: ATCUser) {
        guard let fromUser = fromUser else { return }
        self.socialManager.acceptFriendRequest(viewer: toUser, from: fromUser) {
            NotificationCenter.default.post(name: kFriendsUpdateNotificationName, object: nil, userInfo: nil)
            self.fetchFriendships(viewer: self.loggedInUser)
        }
        friendships.filter({ $0.otherUser == fromUser }).first?.type = .mutual
        let message = "\(toUser.fullName()) " + "accepted your friend request".localizedChat
        let notificationSender = ATCPushNotificationSender()
        if let token = toUser.pushToken, toUser.uid != fromUser.uid {
            notificationSender.sendPushNotification(to: token, title: "iMessenger", body: message)
        }
    }
    
    func cancelFriendRequest(fromUser: ATCUser?, toUser: ATCUser) {
        guard let fromUser = fromUser else { return }
        self.socialManager.cancelFriendRequest(viewer: fromUser, to: toUser) {
            self.fetchFriendships(viewer: self.loggedInUser)
        }
        friendships = friendships.filter({ $0.otherUser != toUser })
    }
    
    func unFriendRequest(fromUser: ATCUser?, toUser: ATCUser) {
        guard let fromUser = fromUser else { return }
        self.socialManager.cancelFriendRequest(viewer: fromUser, to: toUser) {
            self.socialManager.cancelFriendRequest(viewer: toUser, to: fromUser) {
                self.fetchFriendships(viewer: self.loggedInUser)
            }
        }
        friendships = friendships.filter({ $0.otherUser != toUser })
    }
    
    func updateFriendshipsCounts(userID: String, inBoundFriendsCount: Int? = nil, outBoundFriendsCount: Int? = nil) {
        if inBoundFriendsCount == nil && outBoundFriendsCount == nil {
            return
        }
        let usersRef = Firestore.firestore().collection("users").document(userID)
        var data: [String: Any] = [:]
        if let inBoundFriendsCount = inBoundFriendsCount {
            data["inboundFriendsCount"] = inBoundFriendsCount
        }
        if let outBoundFriendsCount = outBoundFriendsCount {
            data["outboundFriendsCount"] = outBoundFriendsCount
        }
        usersRef.setData(data, merge: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: kFriendsRequestNotificationName, object: nil)
        if isFromChatHome {
            NotificationCenter.default.removeObserver(self, name: kFriendsUpdateNotificationName, object: nil)
        }
    }
}
