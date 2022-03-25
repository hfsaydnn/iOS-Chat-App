//
//  CBZConversationsViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 24/04/21.
//

import SwiftUI
import FirebaseFirestore

let kConversationsScreenVisibleNotificationName = NSNotification.Name(rawValue: "kConversationsScreenVisibleNotificationName")
let kConversationsScreenHiddenNotificationName = NSNotification.Name(rawValue: "kConversationsScreenHiddenNotificationName")

class CBZConversationsViewModel: ObservableObject {
 
    var allChannels: [CBZChatChannel] = []
    @Published var channels: [CBZChatChannel] = []
    @Published var isChannelsFetching: Bool = false {
        didSet {
            if !isChannelUpdateNeeded {
                return
            }
            if showLoaderCount == 0 && isChannelsFetching {
                showLoader = true
                showLoaderCount += 1
            } else if showLoader && !isChannelsFetching {
                showLoader = false
            }
            
            if !isChannelsFetching {
                self.updatingTime = Date()
            }
        }
    }
    @Published var updatingTime: Date = Date()
    @Published var showLoader: Bool = true
    @Published var showLoaderCount = 0
    var isChannelUpdateNeeded: Bool = true
    var participationListener: ListenerRegistration? = nil
    var channelListener: ListenerRegistration? = nil
    var user: ATCUser? = nil
    var isNewMessageReceived = false
    var selectedChannel: CBZChatChannel = CBZChatChannel(id: "", name: "")
    
    init(user: ATCUser?) {
        self.user = user
        self.startChannelListeners()
        NotificationCenter.default.addObserver(self, selector: #selector(self.conversationsScreenVisibleNotification(notification:)), name: kConversationsScreenVisibleNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.conversationsScreenHiddenNotification(notification:)), name: kConversationsScreenHiddenNotificationName, object: nil)
    }
    
    @objc func conversationsScreenVisibleNotification(notification: Notification) {
        if isNewMessageReceived {
            isNewMessageReceived = false
            self.channels = self.allChannels
        }
        isChannelUpdateNeeded = true
        fetchChannels()
    }
    
    @objc func conversationsScreenHiddenNotification(notification: Notification) {
        isChannelUpdateNeeded = false
    }
    
    func startChannelListeners() {
        participationListener = Firestore.firestore().collection("channel_participation").addSnapshotListener({[weak self] (querySnapshot, error) in
            guard let strongSelf = self else { return }
            guard let snapshot = querySnapshot else {
                print("Error listening for channel participation updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            snapshot.documentChanges.forEach { change in
                let data = change.document.data()
                var channelNeedsUpdate = false
                
                if let channel = data["channel"] as? String {
                    channelNeedsUpdate = strongSelf.channels.filter { $0.id == channel }.count != 0
                }
                if data["user"] as? String == strongSelf.user?.uid || channelNeedsUpdate {
                    strongSelf.fetchChannels()
                }
            }
        })

        channelListener = Firestore.firestore().collection("channels").addSnapshotListener({[weak self] (querySnapshot, error) in
            guard let strongSelf = self else { return }
            guard querySnapshot != nil else {
                print("Error listening for channel participation updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            guard (strongSelf.user?.uid) != nil else { return }
            strongSelf.fetchChannels()
        })
    }
    
    func fetchChannels() {
        if !isChannelUpdateNeeded { return }
        guard let user = user, let uid = user.uid else { return }
        isChannelsFetching = true
        ATCFirebaseUserReporter().userIDsBlockedOrReported(by: user) { (illegalUserIDsSet) in
            let ref = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uid)
            let channelsRef = Firestore.firestore().collection("channels")
            let usersRef = Firestore.firestore().collection("users")
            ref.getDocuments { (querySnapshot, error) in
                if error != nil {
                    self.isChannelsFetching = false
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                var channels: [CBZChatChannel] = []
                let documents = querySnapshot.documents
                if (documents.count == 0) {
                    self.isChannelsFetching = false
                    return
                }
                for document in documents {
                    let data = document.data()
                    if let channelID = data["channel"] as? String {
                        channelsRef
                            .document(channelID)
                            .getDocument(completion: { (document, error) in
                                if let document = document, var channel = CBZChatChannel(document: document) {
                                    let otherUsers = Firestore.firestore().collection("channel_participation").whereField("channel", isEqualTo: channel.id)
                                    otherUsers.getDocuments(completion: { (snapshot, error) in
                                        guard let snapshot = snapshot else { return }
                                        let docs = snapshot.documents
                                        var docsCount = docs.count
                                        var participants: [ATCUser] = []
                                        if docsCount == 0 {
                                            self.stopLoader()
                                            return
                                        }
                                        for doc in docs {
                                            let data = doc.data()
                                            if let userID = data["user"] as? String {
                                                usersRef
                                                    .document(userID)
                                                    .getDocument(completion: { (document, error) in
                                                        if let document = document,
                                                            let rep = document.data() {
                                                            let participant = ATCUser(representation: rep)
                                                            if channel.groupCreatorID == user.uid {
                                                                participant.isAdmin = true
                                                            }
                                                            if let isAdmin = data["isAdmin"] as? Bool {
                                                                participant.isAdmin = isAdmin
                                                            }
                                                            participants.append(participant)
                                                            if participants.count == docsCount {
                                                                channel.participants = participants
                                                                
                                                                channels.append(channel)
                                                                if channels.count == documents.count {
                                                                    let sortedChannels = self.sort(channels: self.filter(channels: channels, illegalUserIDsSet: illegalUserIDsSet))
                                                                    self.refreshChannelData(fetchedChannels: sortedChannels)
                                                                }
                                                            }
                                                        } else {
                                                            docsCount -= 1
                                                            if participants.count == docsCount {
                                                                channel.participants = participants
                                                                channels.append(channel)
                                                                if channels.count == documents.count {
                                                                    let sortedChannels = self.sort(channels: self.filter(channels: channels, illegalUserIDsSet: illegalUserIDsSet))
                                                                    self.refreshChannelData(fetchedChannels: sortedChannels)
                                                                }
                                                            }
                                                        }
                                                    })
                                            }
                                        }
                                    })
                                } else {
                                    self.stopLoader()
                                    return
                                }
                            })
                    } else {
                        self.stopLoader()
                        return
                    }
                }
            }
        }
    }
    
    private func refreshChannelData(fetchedChannels: [CBZChatChannel]) {
        self.allChannels = fetchedChannels
        if isChannelUpdateNeeded {
            self.channels = self.allChannels
        } else {
            isNewMessageReceived = true
        }
        self.stopLoader()
    }
    
    private func stopLoader() {
        if isChannelUpdateNeeded {
            self.isChannelsFetching = false
        }
    }
    
    func sort(channels: [CBZChatChannel]) -> [CBZChatChannel] {
        let sortedChannels = channels.sorted(by: {$0.lastMessageDate > $1.lastMessageDate})
        var channels: [CBZChatChannel] = []
        for var channel in sortedChannels {
            channel.participants = removeParticipantDuplicates(channel.participants)
            channels.append(channel)
        }
        return channels
    }
    
    func removeParticipantDuplicates(_ participants: [ATCUser]) -> [ATCUser] {
        var noDuplicates = [ATCUser]()
        var usedIDs = [String]()
        for participant in participants {
            if let id = participant.uid, !usedIDs.contains(id) {
                noDuplicates.append(participant)
                usedIDs.append(id)
            }
        }
        return noDuplicates
    }
    
    func filter(channels: [CBZChatChannel], illegalUserIDsSet: Set<String>) -> [CBZChatChannel] {
        var validChannels: [CBZChatChannel] = []
        channels.forEach { (channel) in
            if !channel.participants.contains(where: { (user) -> Bool in
                return illegalUserIDsSet.contains(user.uid ?? "")
            }) {
                validChannels.append(channel)
            }
        }
        return validChannels
    }
}
