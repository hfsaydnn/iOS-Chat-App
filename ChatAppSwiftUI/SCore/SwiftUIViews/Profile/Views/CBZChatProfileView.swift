//
//  CBZChatProfileView.swift
//  ChatApp
//
//  Created by Mayil Kannan on 27/07/21.
//

import SwiftUI
import YPImagePicker

struct CBZChatProfileView: View {
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
                    VStack(alignment: HorizontalAlignment.center) {
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
                        }
                        .padding()
                        Text(viewModel.viewer?.fullName() ?? "")
                        CBZProfileSettings(viewModel: viewModel, store: store, appConfig: appConfig, uiConfig: uiConfig, title: "", clearBackground: true)
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
                                    ) : AnyView(EmptyView()))
        }
        .navigationBarHidden(hideNavigationBar)
    }
}
