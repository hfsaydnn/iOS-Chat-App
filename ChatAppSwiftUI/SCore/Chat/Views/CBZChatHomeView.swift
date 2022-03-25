//
//  CBZChatHomeView.swift
//  ChatApp
//
//  Created by Mayil Kannan on 19/07/21.
//

import SwiftUI

struct CBZChatHomeView: View {
    @ObservedObject var store: CBZPersistentStore
    var viewer: ATCUser? = nil
    @StateObject private var viewModel: CBZChatFriendsViewModel
    @StateObject private var conversationViewModel: CBZConversationsViewModel
    @State var searchText: String = ""
    @State private var showUsersWithOutFollowersModal: Bool = false
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(store: CBZPersistentStore, loggedInUser: ATCUser?, viewer: ATCUser?, isFollowersFollowingEnabled: Bool = false, showFollowers: Bool = false, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self._viewModel = StateObject(wrappedValue: CBZChatFriendsViewModel(isFollowersFollowingEnabled: isFollowersFollowingEnabled, showFollowers: showFollowers, loggedInUser: loggedInUser, isFromChatHome: true))
        self._conversationViewModel = StateObject(wrappedValue: CBZConversationsViewModel(user: viewer))
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    if !viewModel.isFollowersFollowingEnabled {
                        ZStack {
                            CBZSearchBar(placeHolder: "Search for friends".localizedChat, text: $searchText, completionHandler: { (searchText) in
                            }, cancelHandler: {
                                self.presentationMode.wrappedValue.dismiss()
                            }, defaultCancelShow: false, uiConfig: uiConfig)
                            .padding([.leading,.trailing], 5)
                            .padding(.top, 10)
                            .allowsHitTesting(false)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showUsersWithOutFollowersModal = true
                        }
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack() {
                            if !viewModel.showLoader {
                                LazyHStack {
                                    ForEach(viewModel.friends, id: \.self) { user in
                                        NavigationLink(destination: CBZChatThreadView(viewer: viewer, channel: getChannel(user: user), appConfig: appConfig, uiConfig: uiConfig, conversationsViewModel: conversationViewModel)) {
                                            CBZRoundedFriendsView(user: user, uiConfig: uiConfig)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.id(viewModel.updatingTime)
                    }
                    VStack() {
                        if !conversationViewModel.showLoader {
                            if conversationViewModel.channels.count == 0 {
                                CBZEmptyView(title: "No Conversations".localizedChat, subTitle: "Start chatting with the people you follow. Your conversations will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, uiConfig: uiConfig, completionHandler: {
                                })
                                    .padding(.top, 50)
                            }
                            LazyVStack {
                                ForEach(conversationViewModel.channels) { channel in
                                    CBZConversationView(channel: channel, viewer: viewer, appConfig: appConfig, uiConfig: uiConfig, conversationViewModel: conversationViewModel)
                                }
                            }
                        }
                        Spacer()
                    }.id(conversationViewModel.updatingTime)
                    .navigationBarTitle((!viewModel.isFollowersFollowingEnabled ? "People" : viewModel.showFollowers ? "Followers" : "Following").localizedChat, displayMode: .inline)
                    .navigationBarItems(leading: viewModel.isFollowersFollowingEnabled ?
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
                                        trailing:
                                            NavigationLink(destination: CBZChatGroupMembersView(viewer: viewer, appConfig: appConfig, uiConfig: uiConfig, isChatApp: true)) {
                                                Image("inscription")
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .frame(width: 25, height: 25)
                                                    .foregroundColor(Color(uiConfig.mainTextColor))
                                            })
                }
            }
            .onAppear {
                viewModel.isChatHomeVisible = true
            }
            .onDisappear {
                viewModel.isChatHomeVisible = false
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
        .fullScreenCover(isPresented: self.$showUsersWithOutFollowersModal) {
            CBZChatFriendsView(store: store, loggedInUser: viewModel.loggedInUser, viewer: viewer, showUsersWithOutFollowers: true, appConfig: appConfig, uiConfig: uiConfig)
                .onAppear {
                    viewModel.isChatHomeVisible = false
                }
                .onDisappear {
                    viewModel.isChatHomeVisible = true
                }
        }
        .navigationBarHidden(viewModel.isFollowersFollowingEnabled)
    }
    
    func getChannel(user: ATCUser) -> CBZChatChannel {
        if let viewer = viewer {
            let id1 = (viewer.uid ?? "")
            let id2 = (user.uid ?? "")
            let channelId = id1 < id2 ? id1 + id2 : id2 + id1
            let channel = CBZChatChannel(id: channelId, name: user.fullName())
            channel.participants = [viewer, user]
            return channel
        }
        return CBZChatChannel(id: "", name: "")
    }
}

struct CBZRoundedFriendsView: View {
    var user: ATCUser
    var uiConfig: CBZUIConfigurationProtocol
    let imageHeight:CGFloat = 58

    var body: some View {
        VStack(alignment: HorizontalAlignment.center) {
            VStack {
                if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                    CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!,
                                    needUniqueID: true)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: imageHeight, height: imageHeight)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: imageHeight, height: imageHeight)
                        .id(UUID())
                }
            }
            .padding(4)
            Text(userName)
                .font(uiConfig.regularFont(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .id(UUID())
        }
    }
    
    var userName: String {
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        return user.lastName ?? ""
    }
}
