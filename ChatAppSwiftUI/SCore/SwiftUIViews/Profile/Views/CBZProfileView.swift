//
//  CBZProfileView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 10/04/21.
//

import SwiftUI
import YPImagePicker

struct CBZProfileView: View {
    @ObservedObject var store: CBZPersistentStore
    var viewer: ATCUser? = nil
    @ObservedObject private var viewModel: CBZProfileViewModel
    var feedViewModel: CBZFeedViewModel
    let userManager = ATCSocialFirebaseUserManager()
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @State var profileActionText = "Profile Settings".localizedFeed
    @State var isFollowing: Bool?
    var friendsViewModel: CBZFriendsViewModel = CBZFriendsViewModel()
    @State var isLinkActive = false
    @State var channel: CBZChatChannel?
    var hideNavigationBar: Bool
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showNotification: Bool = false
    @State var showProfileImageAction: Bool = false
    @State var showImagePicker: Bool = false
    @State private var isMediaPickerPresented = false
    @State var selectedItems: [YPMediaItem] = []
    @State private var isNewPostPresented = false

    init(store: CBZPersistentStore, loggedInUser: ATCUser?, viewer: ATCUser?, isFollowing: Bool? = nil, hideNavigationBar: Bool, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.hideNavigationBar = hideNavigationBar
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = CBZProfileViewModel(loggedInUser: loggedInUser, viewer: viewer)
        feedViewModel = CBZFeedViewModel(loggedInUser: viewer)
        self.viewModel.loggedInUser = loggedInUser
        if let loggedInUser = loggedInUser {
            self.viewModel.pushNotificationManager = ATCPushNotificationManager(user: loggedInUser)
        }
    }
    
    var sheet: ActionSheet {
        ActionSheet(
            title: Text("Change Photo".localizedFeed),
            message: Text("Change your profile photo".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.showImagePicker = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.showImagePicker = true
                }),
                .default(Text("Remove Photo".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.viewModel.uiImage = nil
                    self.viewModel.isProfileImageUpdated = true
                    self.viewModel.removePhoto()
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.showProfileImageAction = false
                })
            ])
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if viewModel.isInitialPostFetched {
                    VStack(alignment: HorizontalAlignment.leading) {
                        HStack(alignment: VerticalAlignment.center, spacing: 20) {
                            VStack {
                                if viewModel.isProfileImageUpdated {
                                    Image(uiImage: viewModel.uiImage ?? UIImage(named: "empty-avatar")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if (viewModel.viewer?.profilePictureURL == nil) {
                                    Image("empty-avatar")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    CBZNetworkImage(imageURL: URL(string: (viewModel.viewer?.profilePictureURL)!)!,
                                                    placeholderImage: UIImage(named: "empty-avatar")!)
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                }
                            }.contentShape(Rectangle())
                            .onTapGesture {
                                if let viewer = viewer, let loggedInUser = viewModel.loggedInUser, viewer.uid == loggedInUser.uid {
                                    showProfileImageAction = true
                                }
                            }
                            VStack {
                                Text("\(viewModel.posts.count)")
                                    .foregroundColor(Color(uiConfig.mainTextColor))
                                Text("Posts".localizedCore)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(uiConfig.regularFont(size: 15))
                                    .foregroundColor(Color(uiConfig.mainTextColor))
                            }
                            NavigationLink(destination: CBZFriendsView(store: store, loggedInUser: viewModel.loggedInUser, viewer: viewer, isFollowersFollowingEnabled: true, showFollowers: true, appConfig: appConfig, uiConfig: uiConfig)) {
                                VStack {
                                    Text("\(viewModel.viewer?.inboundFriendsCount ?? 0)")
                                        .foregroundColor(Color(uiConfig.mainTextColor))
                                    Text("Followers".localizedChat)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(uiConfig.regularFont(size: 15))
                                        .foregroundColor(Color(uiConfig.mainTextColor))
                                }
                            }.disabled((viewModel.viewer?.inboundFriendsCount ?? 0) == 0)
                            NavigationLink(destination: CBZFriendsView(store: store, loggedInUser: viewModel.loggedInUser,viewer: viewer, isFollowersFollowingEnabled: true, showFollowers: false, appConfig: appConfig, uiConfig: uiConfig)) {
                                VStack {
                                    Text("\(viewModel.viewer?.outboundFriendsCount ?? 0)")
                                        .foregroundColor(Color(uiConfig.mainTextColor))
                                    Text("Following".localizedChat)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(uiConfig.regularFont(size: 15))
                                        .foregroundColor(Color(uiConfig.mainTextColor))
                                }
                            }.disabled((viewModel.viewer?.outboundFriendsCount ?? 0) == 0)
                            Spacer()
                        }
                        .padding()
                        HStack {
                            Text(viewModel.viewer?.fullName() ?? "")
                                .padding(.leading, 25)
                            Spacer()
                        }
                        NavigationLink(destination:
                                        VStack {
                                            if let viewer = viewer, viewer.uid != viewModel.loggedInUser?.uid {
                                                if let isFollowing = isFollowing, !isFollowing {
                                                    AnyView(EmptyView())
                                                } else {
                                                    CBZChatThreadView(viewer: viewModel.loggedInUser, channel: channel ?? CBZChatChannel(id: "", name: ""), appConfig: appConfig, uiConfig: uiConfig)
                                                }
                                            } else {
                                                CBZProfileSettings(viewModel: viewModel, store: store, appConfig: appConfig, uiConfig: uiConfig)
                                            }
                                        }
                                       , isActive: $isLinkActive) {
                            Button(action: {
                                if let viewer = viewer, let loggedInUser = viewModel.loggedInUser, viewer.uid != loggedInUser.uid {
                                    if let isFollowing = isFollowing, !isFollowing {
                                        profileActionText = "Send Direct Message".localizedChat
                                        self.isFollowing = true
                                        friendsViewModel.addFriendRequest(fromUser: loggedInUser, toUser: viewer)
                                    } else {
                                        let id1 = (viewer.uid ?? "")
                                        let id2 = (viewModel.loggedInUser?.uid ?? "")
                                        let channelId = id1 < id2 ? id1 + id2 : id2 + id1
                                        let channel = CBZChatChannel(id: channelId, name: viewer.fullName())
                                        channel.participants = [viewer, loggedInUser]
                                        self.channel = channel
                                        isLinkActive = true
                                    }
                                } else {
                                    isLinkActive = true
                                }
                            }) {
                                Text(profileActionText)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 45)
                            .foregroundColor(Color.white)
                            .background(Color(uiConfig.mainThemeForegroundColor))
                            .cornerRadius(8)
                            .padding(.horizontal, 25)
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                        }
                        NavigationLink(destination: CBZNotificationsView(viewer: viewer, appConfig: appConfig, uiConfig: uiConfig), isActive: $showNotification) {
                        }
                        ScrollView(showsIndicators: false) {
                            if !viewModel.isPostFetching {
                                if viewModel.posts.count == 0 {
                                    CBZEmptyView(title: "No Posts".localizedFeed, subTitle: "There are currently no posts on this profile. All the posts will show up here.".localizedFeed, buttonTitle: "Add Your First Post".localizedFeed, hideButton: viewer?.uid != viewModel.loggedInUser?.uid, appConfig: appConfig, uiConfig: uiConfig) {
                                        isMediaPickerPresented = true
                                    }
                                    .padding(.top, 50)
                                }
                                LazyVGrid(columns: columns, spacing: 2) {
                                    ForEach(viewModel.posts) { post in
                                        if let postMedia = post.postMedia.first, let postMediaType = post.postMediaType.first {
                                            if postMediaType.contains("video") {
                                                NavigationLink(destination: CBZPostDetailView(post: post, postViewModel: viewModel, viewer: viewModel.viewer, loggedInUser: viewModel.loggedInUser, store: store, appConfig: appConfig, uiConfig: uiConfig)) {
                                                    CBZPostVideoPlayerView(postMedia: postMedia, post: post, feedViewModel: feedViewModel, shouldPlayAllVisibleVideo: true, indexOfPlayer: 0)
                                                        .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                                                }
                                            } else {
                                                NavigationLink(destination: CBZPostDetailView(post: post, postViewModel: viewModel, viewer: viewModel.viewer, loggedInUser: viewModel.loggedInUser, store: store, appConfig: appConfig, uiConfig: uiConfig)) {
                                                    CBZNetworkImage(imageURL: URL(string: postMedia)!,
                                                                    placeholderImage: UIImage(named: "gray-back")!)
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                                                        .clipped()
                                                }
                                            }
                                        } else if let postMedia = post.postMedia.first {
                                            NavigationLink(destination: CBZPostDetailView(post: post, postViewModel: viewModel, viewer: viewModel.viewer, loggedInUser: viewModel.loggedInUser, store: store, appConfig: appConfig, uiConfig: uiConfig)) {
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
                        VStack { }
                            .fullScreenCover(isPresented: $isMediaPickerPresented) {
                                YPImagePickerView(selectedItems: $selectedItems, isNewPostPresented: $isNewPostPresented)
                            }
                        VStack { }
                            .fullScreenCover(isPresented: $isNewPostPresented) {
                                CBZNewPostView(selectedItems: $selectedItems, isNewPostPresented: $isNewPostPresented, viewer: viewer, appConfig: appConfig, uiConfig: uiConfig)
                            }
                        Spacer()
                    }
                    .sheet(isPresented: $showImagePicker, onDismiss: {
                        showImagePicker = false
                    }, content: {
                        CBZImagePicker(isShown: self.$showImagePicker, isShownSheet: self.$showImagePicker)  { (image, url) in
                            if let image = image {
                                self.viewModel.uiImage = image
                            }
                        }
                    })
                    .actionSheet(isPresented: $showProfileImageAction) {
                        sheet
                    }
                }
            }
            .onAppear {
                if let viewer = viewer, viewer.uid != viewModel.loggedInUser?.uid {
                    if let isFollowing = isFollowing, !isFollowing {
                        profileActionText = "Follow".localizedChat
                    } else {
                        profileActionText = "Send Direct Message".localizedChat
                    }
                } else {
                    profileActionText = "Profile Settings".localizedFeed
                }
                
                if let viewer = viewer, let loggedInUser = viewModel.loggedInUser {
                    self.viewModel.viewer = viewer
                    self.viewModel.fetchUserPosts(user: viewer, loggedInUser: loggedInUser)
                    if let viewerUID = viewer.uid {
                        self.userManager.fetchUser(userID: viewerUID, completion: { (user, error) in
                            guard let user = user else { return }
                            self.viewModel.viewer = user
                        })
                    }
                }
            }
            .overlay(
                VStack {
                    CPKProgressHUDSwiftUI()
                }
                .frame(width: 100,
                       height: 100)
                .opacity(viewModel.showLoader ? 1 : 0)
            )
            .navigationBarTitle("Profile".localizedFeed, displayMode: .inline)
            .navigationBarItems(leading: hideNavigationBar ?
                                    AnyView(
                                        Button(action: {
                                            self.presentationMode.wrappedValue.dismiss()
                                        }) {
                                            Image("arrow-back-icon")
                                                .renderingMode(.template)
                                                .resizable()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                                        }
                                    ) : AnyView(EmptyView()),
                                trailing: !hideNavigationBar ?
                                    AnyView(
                                        Button(action: {
                                            self.showNotification = true
                                        }) {
                                            Image("bell")
                                                .renderingMode(.template)
                                                .resizable()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                                        }
                                    ) : AnyView(EmptyView()))
        }
        .navigationBarHidden(hideNavigationBar)
    }
}
