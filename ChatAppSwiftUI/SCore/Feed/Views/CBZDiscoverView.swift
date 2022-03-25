//
//  CBZDiscoverView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 17/04/21.
//

import SwiftUI

struct CBZDiscoverView: View {
    var viewer: ATCUser? = nil
    var loggedInUser: ATCUser? = nil
    @ObservedObject private var viewModel: CBZDiscoverViewModel
    var feedViewModel: CBZFeedViewModel
    @ObservedObject var store: CBZPersistentStore
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(viewer: ATCUser? = nil, loggedInUser: ATCUser?, store: CBZPersistentStore, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.viewer = viewer
        self.store = store
        self.loggedInUser = loggedInUser
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = CBZDiscoverViewModel()
        self.feedViewModel = CBZFeedViewModel(loggedInUser: viewer)
        self.viewModel.fetchDiscoverPosts(loggedInUser: viewer)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    if !viewModel.isPostFetching {
                        if viewModel.posts.count == 0 {
                            CBZEmptyView(title: "Welcome".localizedChat, subTitle: "Go ahead and follow a few friends. Their posts will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, uiConfig: uiConfig)
                                .padding(.top, 50)
                        }
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.posts) { post in
                                if let postMedia = post.postMedia.first, let postMediaType = post.postMediaType.first {
                                    if postMediaType.contains("video") {
                                        NavigationLink(destination: CBZPostDetailView(post: post, postViewModel: viewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig, uiConfig: uiConfig)) {
                                            CBZPostVideoPlayerView(postMedia: postMedia, post: post, feedViewModel: feedViewModel, shouldPlayAllVisibleVideo: true, indexOfPlayer: 0)
                                                .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                                        }
                                    } else {
                                        NavigationLink(destination: CBZPostDetailView(post: post, postViewModel: viewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig, uiConfig: uiConfig)) {
                                            CBZNetworkImage(imageURL: URL(string: postMedia)!,
                                                            placeholderImage: UIImage(named: "gray-back")!)
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                                                .clipped()
                                        }
                                    }
                                } else if let postMedia = post.postMedia.first {
                                    NavigationLink(destination: CBZPostDetailView(post: post, postViewModel: viewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig, uiConfig: uiConfig)) {
                                        CBZNetworkImage(imageURL: URL(string: postMedia)!,
                                                        placeholderImage: UIImage(named: "gray-back")!)
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                                            .clipped()
                                    }
                                }
                            }
                        }
                        .padding(.top, 5)
                    }
                }
            }
            .navigationBarTitle("Explore".localizedChat, displayMode: .inline)
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.isPostFetching ? 1 : 0)
        )
    }
}
