//
//  CBZProfileViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 21/04/21.
//

import SwiftUI
import FirebaseFirestore

class CBZProfileViewModel: ObservableObject, CBZFeedPostManagerProtocol {

    @Published var posts: [CBZPostModel] = []
    @Published var postComments: [CBZPostComment] = []
    @Published var isPostFetching: Bool = false
    var viewer: ATCUser? = nil
    var loggedInUser: ATCUser? = nil
    @Published var showLoader: Bool = false
    let push_notification_key = "push_notifications_enabled"
    let face_id_key = "face_id_enabled"
    var pushNotificationManager: ATCPushNotificationManager?
    private let defaults = UserDefaults.standard
    let profileFirebaseUpdater: ATCProfileFirebaseUpdater = ATCProfileFirebaseUpdater(usersTable: "users")
    @Published var isProfileImageUpdated: Bool = false
    @Published var uiImage: UIImage? = nil {
        didSet {
            if let uiImage = uiImage {
                isProfileImageUpdated = true
                self.updateProfileImage(image: uiImage)
            }
        }
    }
    @Published var shouldShowAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isInitialPostFetched = false
    var isLoggedInUser: Bool = false

    init(loggedInUser: ATCUser?, viewer: ATCUser?) {
        self.loggedInUser = loggedInUser
        if let viewer = viewer, viewer.uid != loggedInUser?.uid {
            self.isLoggedInUser = false
        } else {
            self.isLoggedInUser = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.newPostNotification(notification:)), name: kNewPostAddedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deletedPostNotification(notification:)), name: kMyPostDeletedNotificationName, object: nil)
    }

    @objc func newPostNotification(notification: Notification) {
        if isLoggedInUser {
            if let dictionary = notification.userInfo as? [String: Any] {
                let newPost = CBZPostModel(jsonDict: dictionary)
                newPost.profileImage = loggedInUser?.profilePictureURL ?? ""
                newPost.postUserName = loggedInUser?.fullName()
                self.posts.insert(newPost, at: 0)
            }
        }
    }
    
    @objc func deletedPostNotification(notification: Notification) {
        if isLoggedInUser, let loggedInUser = self.loggedInUser {
            self.fetchUserPosts(user: loggedInUser, loggedInUser: loggedInUser)
        }
    }
    
    func fetchUserPosts(user: ATCUser, loggedInUser: ATCUser) {
        let db = Firestore.firestore()
        let ref = db.collection("SocialNetwork_Posts")
        guard let userUID = user.uid else { return }
        let selfUserRef = ref.whereField("authorID", isEqualTo: userUID).order(by: "createdAt", descending: true)
        var profileUserPosts: [CBZPostModel] = []
        var postreactionstatus: [CBZPostReactionStatus] = []

        if !isInitialPostFetched {
            self.showLoader = true
        }
        
        self.fetchReactions(user: loggedInUser) { (reactions) in
            postreactionstatus = reactions
            selfUserRef.getDocuments { (querySnapshot, error) in
                if !self.isInitialPostFetched {
                    self.isInitialPostFetched = true
                    self.showLoader = false
                }
                if let _ = error {
                    print("Some error occured")
                    return
                }

                guard let snapshot = querySnapshot else { return }
                let documents = snapshot.documents
                for doc in documents {
                    let data = doc.data()
                    let timeStamp = doc["createdAt"] as? Timestamp
                    let date = timeStamp?.dateValue()
                    let newPost = CBZPostModel(jsonDict: data)
                    let id = newPost.id
                    
                    postreactionstatus.contains(where: { (status) -> Bool in
                        if (status.postID == id) {
                            newPost.selectedReaction = status.reaction
                            return true
                        } else {
                            return false
                        }
                    })

                    newPost.createdAt = date
                    newPost.profileImage = user.profilePictureURL ?? ""
                    newPost.postUserName = user.fullName()
                    profileUserPosts.append(newPost)
                }
                
                if profileUserPosts.count == documents.count {
                    self.posts = profileUserPosts
                }
            }
        }
    }
    
    private func fetchReactions(user: ATCUser, completion: @escaping ([CBZPostReactionStatus]) -> Void) {
        let db = Firestore.firestore()
        let reactionRef = db.collection("socialnetwork_reactions")
        guard let loggedInUseruid = user.uid else { return }
        
        let reactionDoc = reactionRef.whereField("reactionAuthorID", isEqualTo: loggedInUseruid)
        var postreactionstatus: [CBZPostReactionStatus] = []
        
        reactionDoc.getDocuments { (snapshot, error) in
            if let _ = error {
                print("Some error")
                return
            }

            guard let querySnapshot = snapshot else { return }
            let documents = querySnapshot.documents
            if (documents.count == 0) {
                completion([])
            }
            for doc in documents {
                let data = doc.data()
                let newPostReactionStatus = CBZPostReactionStatus(jsonDict: data)
                postreactionstatus.append(newPostReactionStatus)

                if postreactionstatus.count == documents.count {
                    completion(postreactionstatus)
                }
            }
        }
    }
    
    func update(email: String, firstName: String, lastName: String, phone: String, completion: @escaping () -> Void) {
        showLoader = true
        let documentRef = Firestore.firestore().collection("users").document("\(loggedInUser?.uid ?? "0")")
        documentRef.setData([
            "firstName" : firstName,
            "lastName"  : lastName,
            "email"     : email,
            "phone"     : phone,
        ], merge: true) { err in
            self.showLoader = false
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Successfully updated")
                self.loggedInUser?.firstName = firstName
                self.loggedInUser?.lastName = lastName
                self.loggedInUser?.email = email
                self.loggedInUser?.phoneNumber = phone
                completion()
            }
        }
    }
    
    func updateSettings(isPushNotificationsEnabled: Bool, isFaceIDOrTouchIDEnabled: Bool) {
        showLoader = true
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        let usersRef = Firestore.firestore().collection("users").document("\(loggedInUser?.uid ?? "0")")
        let userSettingsJSON = [
            "settings": [
                push_notification_key : isPushNotificationsEnabled,
                face_id_key  : isFaceIDOrTouchIDEnabled
            ]
        ]
        usersRef.setData(userSettingsJSON, merge: true) { [weak self] (error) in
            guard let self = self else { return }
            self.showLoader = false
            if error == nil {
                if isPushNotificationsEnabled {
                    self.pushNotificationManager?.updateFirestorePushTokenIfNeeded()
                } else {
                    self.pushNotificationManager?.removeFirestorePushTokenIfNeeded()
                }
                self.defaults.set(userSettingsJSON, forKey: "\(self.loggedInUser?.uid ?? "0")")
                self.loggedInUser?.settings[self.push_notification_key] = isPushNotificationsEnabled
                self.loggedInUser?.settings[self.face_id_key] = isFaceIDOrTouchIDEnabled
            }
        }
    }
    
    func updateProfileImage(image: UIImage) {
        guard let user = loggedInUser else { return }
        showLoader = true
        profileFirebaseUpdater.uploadPhoto(image: image, user: user, isProfilePhoto: true) {[weak self] (success) in
            self?.showLoader = false
        }
    }
    
    func removePhoto() {
        guard let user = loggedInUser else { return }
        let documentRef = Firestore.firestore().collection("users").document("\(user.uid!)")

        showLoader = true
        documentRef.updateData([
            "profilePictureURL" : FieldValue.delete()
        ]) { [weak self] (error) in
            user.profilePictureURL = ATCUser.defaultAvatarURL
            self?.showLoader = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: kNewPostAddedNotificationName, object: nil)
    }
}
