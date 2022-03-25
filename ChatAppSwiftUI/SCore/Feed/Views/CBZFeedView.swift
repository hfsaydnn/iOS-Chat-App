//
//  CBZFeedView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 08/04/21.
//

import SwiftUI
import YPImagePicker

struct CBZFeedView: View {
    var viewer: ATCUser? = nil
    @ObservedObject private var viewModel: CBZFeedViewModel
    @State var selectedItems: [YPMediaItem] = []
    @State private var isMediaPickerPresented = false
    @State private var isNewPostPresented = false
    @State private var isStoryContentPresented = false
    @State private var selectedStories: [ATCStory] = []
    @State private var isEditStoryViewPresented = false
    @State private var editStoryImage: UIImage = UIImage()
    @State private var isEditStoryImagePicked: Bool = false
    @State var showAction: Bool = false
    @State var showImagePicker: Bool = false
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @ObservedObject var store: CBZPersistentStore
    @State var userStoriesIndex: Int = 0
    @Binding var tabSelection: Int

    init(viewer: ATCUser? = nil, store: CBZPersistentStore, tabSelection: Binding<Int>, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.viewer = viewer
        self.viewModel = CBZFeedViewModel(loggedInUser: viewer)
        self.store = store
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self._tabSelection = tabSelection
    }
    
    var sheet: ActionSheet {
        ActionSheet(
            title: Text(""),
            message: Text("Create a New Story From"),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.showAction = false
                    self.showImagePicker = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.showAction = false
                    self.showImagePicker = true
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.showAction = false
                })
            ])
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack() {
                    if viewModel.isStoryChanged { }
                    CBZStoryView(storiesUserState: $viewModel.storiesUserState, isStoryContentPresented: $isStoryContentPresented, selectedStories: $selectedStories, showImagePickerOption: $showAction, userStoriesIndex: $userStoriesIndex, feedViewModel: viewModel, appConfig: appConfig, uiConfig: uiConfig)
                        .frame(height: 105)
                        .padding(.leading, 5)
                        .padding(.top, 10)
                    Divider()
                        .padding(.vertical, 5)
                    if !viewModel.isPostFetching {
                        if viewModel.posts.count == 0 {
                            CBZEmptyView(title: "Welcome".localizedChat, subTitle: "Go ahead and follow a few friends. Their posts will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, uiConfig: uiConfig, completionHandler: {
                                tabSelection = 3
                            })
                                .padding(.top, 50)
                        }
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.posts) { post in
                                if post.postMedia.first != nil {
                                    CBZPostView(post: post, postViewModel: viewModel, viewer: viewer, loggedInUser: viewer, store: store, appConfig: appConfig, uiConfig: uiConfig)
                                }
                            }
                        }
                    }
                    Spacer()
                }
                VStack { }
                    .fullScreenCover(isPresented: $isMediaPickerPresented) {
                        YPImagePickerView(selectedItems: $selectedItems, isNewPostPresented: $isNewPostPresented)
                    }
                VStack { }
                    .fullScreenCover(isPresented: $isNewPostPresented) {
                        CBZNewPostView(selectedItems: $selectedItems, isNewPostPresented: $isNewPostPresented, viewer: viewer, appConfig: appConfig, uiConfig: uiConfig)
                    }
                VStack { }
                    .fullScreenCover(isPresented: $isStoryContentPresented) {
                        CBZStoryContentView(isStoryContentPresented: $isStoryContentPresented, selectedStories: $selectedStories, storiesUserState: $viewModel.storiesUserState, userStoriesIndex: $userStoriesIndex)
                    }
                VStack { }
                    .fullScreenCover(isPresented: $isEditStoryViewPresented) {
                        CBZEditStoryView(isEditStoryViewPresented: $isEditStoryViewPresented,
                                         editStoryImage: $editStoryImage,
                                         viewer: viewer,
                                         storyFeedViewModel: viewModel,
                                         uiConfig: uiConfig)
                    }
                VStack { }
                    .sheet(isPresented: $showImagePicker, onDismiss: {
                        showImagePicker = false
                        if isEditStoryImagePicked {
                            isEditStoryImagePicked = false
                            isEditStoryViewPresented = true
                        }
                    }, content: {
                        CBZImagePicker(isShown: self.$showImagePicker, isShownSheet: self.$showAction, allMedia: false) { (image, url) in
                            if let image = image {
                                editStoryImage = image
                                isEditStoryImagePicked = true
                            }
                        }
                    })
            }
            .navigationBarTitle("Instamobile", displayMode: .inline)
            .navigationBarItems(leading:
                                    Button(action: {
                                        self.showAction = true
                                    }) {
                                        Image("camera-icon")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(Color(uiConfig.mainTextColor))
                                    }, trailing:
                                    Button(action: {
                                        self.isMediaPickerPresented = true
                                    }) {
                                        Image("inscription")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(Color(uiConfig.mainTextColor))
                                    })
        }
        .actionSheet(isPresented: $showAction) {
            sheet
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showLoader ? 1 : 0)
        )
        .onAppear {
            if !self.viewModel.isNewsFeedUpdated {
                self.viewModel.fetchNewsFeed()
                self.viewModel.isNewsFeedUpdated = true
            }
            self.viewModel.fetchStories()
        }
    }
}
