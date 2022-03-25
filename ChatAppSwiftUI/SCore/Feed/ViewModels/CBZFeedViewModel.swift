//
//  CBZFeedViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 12/04/21.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class CBZFeedViewModel: ObservableObject, CBZFeedPostManagerProtocol {

    @Published var posts: [CBZPostModel] = []
    @Published var postComments: [CBZPostComment] = []
    @Published var isPostFetching: Bool = false
    @Published var showLoader: Bool = false
    @Published var storiesUserState: CBZStoriesUserState = CBZStoriesUserState()
    @Published var isStoryChanged: Bool = false
    @Published var shouldShowAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    let socialManager = CBZFirebaseSocialGraphManager()
    let userManager = ATCSocialFirebaseUserManager()
    var isNewsFeedUpdated: Bool = false
    var loggedInUser: ATCUser?
    @Published var storyUpdatingTime: Date = Date()

    init(loggedInUser: ATCUser?) {
        self.loggedInUser = loggedInUser
        NotificationCenter.default.addObserver(self, selector: #selector(self.newPostNotification(notification:)), name: kNewPostAddedNotificationName, object: nil)
    }
    
    @objc func newPostNotification(notification: Notification) {
        if let dictionary = notification.userInfo as? [String: Any] {
            let newPost = CBZPostModel(jsonDict: dictionary)
            newPost.profileImage = loggedInUser?.profilePictureURL ?? ""
            newPost.postUserName = loggedInUser?.fullName()
            self.posts.insert(newPost, at: 0)
        }
    }
    
    func fetchNewsFeed() {
        let serialQueue = DispatchQueue(label: "com.iosAppTemplate.Queue")
        
        let db = Firestore.firestore()
        let ref = db.collection("SocialNetwork_Posts")
        
        guard let loggedInUser = loggedInUser else { return }
        
        guard let loggedInUseruid = loggedInUser.uid else { return }
        var loggedInUserPost: [CBZPostModel] = []
        var allSelfPosts: [CBZPostModel] = []
        
        let selfReference = ref.whereField("authorID", isEqualTo: loggedInUseruid).order(by: "createdAt", descending: true)
        var postReactionStatus : [CBZPostReactionStatus] = []
        
        showLoader = true
        isPostFetching = true
        
        self.fetchReactions(user: loggedInUser) { (postReactions) in
            postReactionStatus = postReactions
            print("Reaction count = \(postReactions.count)")
            
            // Fetching Self Posts
            selfReference.getDocuments { (snapshot, error) in
                if let _ = error {
                    return
                }
                print("Newsfeed reaction 2")
                guard let querySnapshot = snapshot else { return }
                let docs = querySnapshot.documents
                
                for doc in docs {
                    let data = doc.data()
                    let timeStamp = doc["createdAt"] as? Timestamp
                    let date = timeStamp?.dateValue()
                    let newPost = CBZPostModel(jsonDict: data)
                    
                    let id = newPost.id
                    
                    postReactionStatus.contains(where: { (status) -> Bool in
                        if (status.postID == id) {
                            newPost.selectedReaction = status.reaction
                            return true
                        } else {
                            return false
                        }
                    })
                    
                    newPost.createdAt = date
                    newPost.profileImage = loggedInUser.profilePictureURL ?? ""
                    newPost.postUserName = loggedInUser.fullName()
                    serialQueue.sync {
                        loggedInUserPost.append(newPost)
                    }
                    
                    if loggedInUserPost.count == docs.count {
                        allSelfPosts = loggedInUserPost
                    }
                }
                
                // Fetching Friend's Posts
                var friendPosts: [CBZPostModel] = []
                var friendsPostRetrieved: [ATCUser] = []
                
                //Fetching friends here
                print("Newsfeed reaction 3")
                self.socialManager.fetchInBoundOutBoundUsers(viewer: loggedInUser, isInBoundUsers: false) { (fetchedFriends) in
                    let allfriends = fetchedFriends
                    if (allfriends.count == 0) {
                        let sortedPosts = allSelfPosts.sorted(by: { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) })
                        self.showLoader = false
                        self.isPostFetching = false
                        self.posts = sortedPosts
                        return
                    }
                    for friend in allfriends {
                        guard let friendUID = friend.uid else { return }
                        let postsRef = ref.whereField("authorID", isEqualTo: friendUID).order(by: "createdAt", descending: true)
                        
                        postsRef.getDocuments(completion: { (querySnapshot, error) in
                            if let error = error {
                                print(error)
                                self.showLoader = false
                                self.isPostFetching = false
                                return
                            }
                            
                            guard let snapshot = querySnapshot else {
                                self.showLoader = false
                                self.isPostFetching = false
                                return
                            }
                            
                            let documents = snapshot.documents
                            for doc in documents {
                                let data = doc.data()
                                let timeStamp = doc["createdAt"] as? Timestamp
                                let date = timeStamp?.dateValue()
                                let newPost = CBZPostModel(jsonDict: data)
                                
                                
                                let id = newPost.id
                                
                                postReactionStatus.contains(where: { (status) -> Bool in
                                    if (status.postID == id) {
                                        newPost.selectedReaction = status.reaction
                                        return true
                                    } else {
                                        return false
                                    }
                                })
                                
                                newPost.createdAt = date
                                newPost.profileImage = friend.profilePictureURL ?? ""
                                newPost.postUserName = friend.fullName()
                                serialQueue.sync {
                                    friendPosts.append(newPost)
                                }
                            }
                            friendsPostRetrieved.append(friend)
                            print("newsfeed 4")
                            if friendsPostRetrieved.count == fetchedFriends.count {
                                let allposts = friendPosts + allSelfPosts
                                let sortedPosts = allposts.sorted(by: { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) })
                                self.showLoader = false
                                self.isPostFetching = false
                                self.posts = sortedPosts
                            }
                        })
                    }
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
    
    func fetchStories() {
        guard let loggedInUser = loggedInUser else { return }

        // fetch stories here
        // 1. Fetch friends and for each friend check for stories
        let db = Firestore.firestore()
        let storiesReference = db.collection("socialnetwork_stories")
        let storiesUserState = CBZStoriesUserState()
    
        var friendsStories  : [[ATCStory]] = []
        var friendsStoryRetrieved: [ATCUser] = []
        
        var selfStories: [ATCStory] = []
        var friendUsers: [ATCUser] = []
        
        let currentTime = Date()
        
        guard let loggedInUserUID = loggedInUser.uid else { return }
        let storyRef = storiesReference.whereField("storyAuthorID", isEqualTo: loggedInUserUID)
        
        var selfStoriesFiltered = 0
        

        print("Self Story Check Point 1")
        storyRef.getDocuments { (snapshot, error) in
            if let _ = error {
                print("Something went wrong")
                return
            }
            
            guard let querySnapshot = snapshot else { return }
            
            let documents = querySnapshot.documents
            if documents.count == 0 {
                selfStories = []
                storiesUserState.selfStory = false
            }else {
                for doc in documents {
                    let data = doc.data()
                    let storyCreationDate = doc["createdAt"] as? Timestamp
                    let storyDate = storyCreationDate?.dateValue()
                    let difference = Calendar.current.dateComponents([.hour, .minute], from: storyDate ?? Date(), to: currentTime)
                    let hours = difference.hour
                   
    
                    guard let differencehour = hours else {
                        print("Couldn't retrieve hours")
                        return
                        
                    }
                    if differencehour >= 24 {
                            selfStoriesFiltered = selfStoriesFiltered + 1
                            // Those stories greater than 24 hour difference to be removed from server
                    } else {
                            let story = ATCStory(jsonDict: data)
                            selfStories.append(story)
                        }
                    
                   
                    if selfStories.count == (documents.count - selfStoriesFiltered) && selfStories.count > 0 {
                        storiesUserState.selfStory = true
                        friendsStories.append(selfStories)
                        self.userManager.fetchUser(userID: loggedInUserUID, completion: { (user, error) in
                            guard let user = user else { return }
                            friendUsers.append(user)
                        })
                    }
                }
  
            }
            
        
        
        print("Self Story Check Point 2")
        
            self.socialManager.fetchInBoundOutBoundUsers(viewer: loggedInUser, isInBoundUsers: false) { (fetchedFriends) in
            let friends = fetchedFriends
            
            if friends.count == 0 && selfStories.count == 0{
                storiesUserState.stories = []
                storiesUserState.users = []
                storiesUserState.selfStory = false
                self.storiesUserState = storiesUserState
                self.isStoryChanged.toggle()
                self.storyUpdatingTime = Date()
                return
            }else if friends.count == 0 && selfStories.count > 0 {
                storiesUserState.stories = friendsStories
                storiesUserState.users = friendUsers
                storiesUserState.selfStory = true
                self.storiesUserState = storiesUserState
                self.isStoryChanged.toggle()
                self.storyUpdatingTime = Date()
                return
            }
            
            var friendsStoriesFiltered = 0
        
            for friend in friends {
                var singleUserStory : [ATCStory] = []
                guard let friendUID = friend.uid else { return }
                let storyRef = storiesReference.whereField("storyAuthorID", isEqualTo: friendUID)
            
                storyRef.getDocuments(completion: { (querySnapshot, error) in
                    if let _ = error {
                        storiesUserState.stories = []
                        storiesUserState.users = []
                        self.storiesUserState = storiesUserState
                        self.isStoryChanged.toggle()
                        self.storyUpdatingTime = Date()
                        return
                    }
                    
                    guard let snapshot = querySnapshot else {
                        storiesUserState.stories = []
                        storiesUserState.users = []
                        self.storiesUserState = storiesUserState
                        self.isStoryChanged.toggle()
                        self.storyUpdatingTime = Date()
                        return
                    }
                    
                    let documents = snapshot.documents
                    
                    
                    if documents.count == 0 && selfStories.count == 0 {
                        storiesUserState.stories = []
                        storiesUserState.users = []
                        storiesUserState.selfStory = false
                        self.storiesUserState = storiesUserState
                        self.isStoryChanged.toggle()
                        self.storyUpdatingTime = Date()
                    } else if documents.count == 0 && selfStories.count > 0 {
                        storiesUserState.stories = friendsStories
                        storiesUserState.users = friendUsers
                        storiesUserState.selfStory = true
                        self.storiesUserState = storiesUserState
                        self.isStoryChanged.toggle()
                        self.storyUpdatingTime = Date()
                    } else if documents.count > 0 && selfStories.count > 0 {
                        storiesUserState.selfStory = true
                    }
                    
                    for doc in documents {
                        let storyCreationDate = doc["createdAt"] as? Timestamp
                        let storyDate = storyCreationDate?.dateValue()
                        let difference = Calendar.current.dateComponents([.hour, .minute], from: storyDate ?? Date(), to: currentTime)
                        let hours = difference.hour
                        
                        
                        guard let differencehour = hours else {
                            print("Couldn't retrieve hours")
                            return
                            
                        }
                        if differencehour >= 24 {
                            // Those stories greater than 24 hour difference to be removed from server
                        } else {
                            let data = doc.data()
                            let newStory = ATCStory(jsonDict: data)
                            singleUserStory.append(newStory)
                        }
                    }
                    
                    // If there exist even one story for a friend, only then append it to friendStoryRetrieved
                    if singleUserStory.count > 0 {
                        friendsStories.append(singleUserStory)
                        friendsStoryRetrieved.append(friend)
                        friendUsers.append(friend)
                    } else {
                        friendsStoriesFiltered = friendsStoriesFiltered + 1
                    }
                    
                    print("Stories fetch check point 3")
                    if friendsStoryRetrieved.count == (fetchedFriends.count - friendsStoriesFiltered) {
                        storiesUserState.stories = friendsStories
                        storiesUserState.users = friendUsers
                        self.storiesUserState = storiesUserState
                        self.isStoryChanged.toggle()
                        self.storyUpdatingTime = Date()
                    }
                })
            }
          }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: kNewPostAddedNotificationName, object: nil)
    }
}
