//
//  CBZDiscoverViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 17/04/21.
//

import SwiftUI
import FirebaseFirestore

class CBZDiscoverViewModel: ObservableObject, CBZFeedPostManagerProtocol {
    
    @Published var posts: [CBZPostModel] = []
    @Published var postComments: [CBZPostComment] = []
    @Published var isPostFetching: Bool = false
    let socialManager = CBZFirebaseSocialGraphManager()
    let userManager = ATCSocialFirebaseUserManager()
    @Published var shouldShowAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    func fetchDiscoverPosts(loggedInUser: ATCUser?) {
        var loggedInUserFriends: [String: Bool] = [:]
        let db = Firestore.firestore()
        let postRef = db.collection("SocialNetwork_Posts")
        guard let loggedInUser = loggedInUser, let userUID = loggedInUser.uid else { return }
        let reactionRef = Firestore.firestore().collection("socialnetwork_reactions")
        var fetchedPosts: [CBZPostModel] = []
        var postreactionstatus: [CBZPostReactionStatus] = []

        guard let loggedInUserUID = loggedInUser.uid else { return }
        loggedInUserFriends = [loggedInUserUID : true]

        isPostFetching = true

        let reactionDoc = reactionRef.whereField("reactionAuthorID", isEqualTo: userUID)
        reactionDoc.getDocuments { (snapshot, error) in
            if let _ = error {
                print("Some error")
                return
            }

            guard let querySnapshot = snapshot else { return }
            let documents = querySnapshot.documents
            for doc in documents {
                let data = doc.data()
                let newPostReactionStatus = CBZPostReactionStatus(jsonDict: data)
                postreactionstatus.append(newPostReactionStatus)
            }
        }

        self.socialManager.fetchInBoundOutBoundUsers(viewer: loggedInUser, isInBoundUsers: false) { (friends) in
            if friends.count > 0 {
                for friend in friends {
                    guard let friendUID = friend.uid else { return }
                    loggedInUserFriends[friendUID] = true
                }
            }
            postRef.getDocuments(completion: { (querySnapshot, error) in
                if let _ = error {
                    return
                }

                guard let snapshot = querySnapshot else { return }
                let documents = snapshot.documents
                var docCount = 0
                
                for doc in documents {
                    let timeStamp = doc["createdAt"] as? Timestamp
                    let date = timeStamp?.dateValue()
                    let data = doc.data()
                    let newPost = CBZPostModel(jsonDict: data)
                    
                    let postAuthorID = newPost.authorID
                    guard let authorID = postAuthorID else { return }
                    let id = newPost.id

                    postreactionstatus.contains(where: { (status) -> Bool in
                        if (status.postID == id) {
                            newPost.selectedReaction = status.reaction
                            return true
                        } else {
                            return false
                        }
                    })

                    if (loggedInUserFriends[authorID] == nil) {
                        self.userManager.fetchUser(userID: authorID, completion: { (user, error) in
                            guard let user = user else {
                                docCount = docCount + 1
                                return
                            }
                            newPost.createdAt = date
                            newPost.profileImage = user.profilePictureURL ?? " "
                            newPost.postUserName = user.fullName()
                            fetchedPosts.append(newPost)
                            print("fetchedPosts.count \(fetchedPosts.count) and \(documents.count - docCount)")
                            if fetchedPosts.count == (documents.count - docCount) {
                                let sortedPosts = fetchedPosts.sorted(by: { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) })
                                self.posts = sortedPosts
                                self.isPostFetching = false
                            }
                        })
                    } else {
                        docCount = docCount + 1
                        print("fetchedPosts.count 22 \(fetchedPosts.count) and \(documents.count - docCount)")
                        if fetchedPosts.count == (documents.count - docCount) {
                            let sortedPosts = fetchedPosts.sorted(by: { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) })
                            self.posts = sortedPosts
                            self.isPostFetching = false
                        }
                    }
                }
            })
        }
    }
}
