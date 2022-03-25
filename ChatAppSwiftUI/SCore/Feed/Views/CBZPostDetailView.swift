//
//  CBZPostDetailView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 15/04/21.
//

import SwiftUI

struct CBZPostDetailView<Model>: View where Model: CBZFeedPostManagerProtocol {
    @ObservedObject var post: CBZPostModel
    @ObservedObject var postViewModel: Model
    var viewer: ATCUser? = nil
    var loggedInUser: ATCUser? = nil
    @State var commentText = ""
    @ObservedObject var store: CBZPersistentStore
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    init(post: CBZPostModel, postViewModel: Model, viewer: ATCUser? = nil, loggedInUser: ATCUser?, store: CBZPersistentStore, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.post = post
        self.postViewModel = postViewModel
        self.viewer = viewer
        self.loggedInUser = loggedInUser
        self.store = store
        self.appConfig = appConfig
        self.uiConfig = uiConfig
    }
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    CBZPostView(post: post, postViewModel: postViewModel, viewer: viewer, loggedInUser: loggedInUser, isPostDetailNavigationDisabled: true, store: store, appConfig: appConfig, uiConfig: uiConfig)
                        .padding(.top, 10)
                    ForEach(postViewModel.postComments) { postComment in
                        CBZPostCommentView(postComment: postComment, uiConfig: uiConfig)
                    }
                }
            }
            HStack {
                TextField("Add a Comment".localizedFeed, text: $commentText)
                    .padding()
                Image("send")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)
                    .padding()
                    .onTapGesture {
                        self.handlePostCommentButton()
                    }
            }
            .background(Color(uiConfig.grey1))
            .frame(height: 45)
        }
        .navigationBarTitle("Post".localizedFeed, displayMode: .inline)
        .onAppear {
            self.postViewModel.postComments.removeAll()
            self.postViewModel.fetchPostComments(post: post)
        }
    }
    
    func handlePostCommentButton() {
        // Handle Post Button To Firebase here
        guard let loggedInUser = viewer else { return }
        guard let loggedInUserUID = loggedInUser.uid else { return }
        guard let postAuthorID = post.authorID else { return }
        let commentComposer = ATCCommentComposerState()
    
        commentComposer.postID = post.id
        commentComposer.commentAuthorID = loggedInUser.uid
        commentComposer.date = Date()
        
        if !(commentText.isEmpty) {
            commentComposer.commentText = commentText
        }else{
            print("No comment to post")
            return
        }
       let notificationComposer = CBZNotificationComposerState(post: post, notificationAuthorID: loggedInUserUID, reacted: false, commented: true, isInteracted: false, createdAt: Date())
        
        if postAuthorID != loggedInUserUID {
            postViewModel.postNotification(composer: notificationComposer) {
                print("Notification Posted")
            }
            let message = "\(loggedInUser.fullName()) " + "commented on your post".localizedFeed
            postViewModel.sendPushToPostUser(message: message, post: post)
        }
        
        postViewModel.saveNewComment(loggedInUser: loggedInUser, commentComposer: commentComposer, post: post) {
            self.commentText = ""
            self.postViewModel.fetchPostComments(post: post)
        }
    }
}
