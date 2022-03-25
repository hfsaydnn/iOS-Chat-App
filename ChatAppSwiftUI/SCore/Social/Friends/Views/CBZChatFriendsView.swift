//
//  CBZChatFriendsView.swift
//  ChatApp
//
//  Created by Mayil Kannan on 22/07/21.
//

import SwiftUI

struct CBZChatFriendsView: View {
    @ObservedObject var store: CBZPersistentStore
    var viewer: ATCUser? = nil
    @StateObject private var viewModel: CBZChatFriendsViewModel
    @State var searchText: String = ""
    var showUsersWithOutFollowers = false
    @State private var showUsersWithOutFollowersModal: Bool = false
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(store: CBZPersistentStore, loggedInUser: ATCUser?, viewer: ATCUser?, showUsersWithOutFollowers: Bool = false, isFollowersFollowingEnabled: Bool = false, showFollowers: Bool = false, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.showUsersWithOutFollowers = showUsersWithOutFollowers
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self._viewModel = StateObject(wrappedValue: CBZChatFriendsViewModel(isFollowersFollowingEnabled: isFollowersFollowingEnabled, showFollowers: showFollowers, loggedInUser: loggedInUser, showUsersWithOutFollowers: showUsersWithOutFollowers, isFromChatFriends: !showUsersWithOutFollowers))
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack() {
                    if showUsersWithOutFollowers {
                        ZStack {
                            CBZSearchBar(placeHolder: "Search for friends".localizedChat, text: $searchText, completionHandler: { (searchText) in
                                if showUsersWithOutFollowers {
                                    if searchText.isEmpty {
                                        viewModel.filteredAllUsers = viewModel.filteredOutBoundAllUsers
                                    } else {
                                        viewModel.filteredAllUsers = viewModel.filteredOutBoundAllUsers.filter({ (user) -> Bool in
                                            return user.fullName().contains(searchText)
                                        })
                                    }
                                }
                            }, cancelHandler: {
                                self.presentationMode.wrappedValue.dismiss()
                            }, defaultCancelShow: showUsersWithOutFollowers, uiConfig: uiConfig)
                            .padding([.leading,.trailing], 5)
                            .padding(.top, showUsersWithOutFollowers ? 10 : 5)
                            .allowsHitTesting(showUsersWithOutFollowers)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !showUsersWithOutFollowers {
                                showUsersWithOutFollowersModal = true
                            }
                        }
                    } else {
                        Spacer()
                            .frame(height: 15)
                    }
                    if !viewModel.showLoader {
                        if showUsersWithOutFollowers {
                            LazyVStack {
                                ForEach(viewModel.filteredAllUsers, id: \.self) { user in
                                    CBZChatFriendView(friendship: nil, viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig, uiConfig: uiConfig)
                                }
                            }
                        } else {
                            if viewModel.friendships.count == 0  {
                                CBZEmptyView(title: "No Friends".localizedChat, subTitle: "Make some friend requests and have your friends accept them. All your friends will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, uiConfig: uiConfig, completionHandler: {
                                    if !showUsersWithOutFollowers {
                                        showUsersWithOutFollowersModal = true
                                    }
                                })
                                    .padding(.top, 50)
                            }
                            LazyVStack {
                                ForEach(viewModel.friendships, id: \.self) { friendship in
                                    NavigationLink(destination: CBZChatThreadView(viewer: viewer, channel: getChannel(user: friendship.otherUser), appConfig: appConfig, uiConfig: uiConfig)) {
                                        CBZChatFriendView(friendship: friendship, viewer: friendship.currentUser, user: friendship.otherUser, viewModel: viewModel, appConfig: appConfig, uiConfig: uiConfig)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }.id(viewModel.updatingTime)
            }
            .onAppear {
                if showUsersWithOutFollowers {
                    self.viewModel.allUsersScreenUpdateNeeded = true
                    self.viewModel.fetchAllUsers(viewer: viewer)
                } else {
                    viewModel.isChatFriendsVisible = true
                }
            }
            .onDisappear {
                if showUsersWithOutFollowers {
                    self.viewModel.allUsersScreenUpdateNeeded = false
                } else {
                    viewModel.isChatFriendsVisible = false
                }
            }
            .navigationBarTitle("Contacts".localizedChat, displayMode: .inline)
            .navigationBarHidden(showUsersWithOutFollowers)
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
                                    ) : AnyView(EmptyView()))
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(((!showUsersWithOutFollowers && viewModel.showLoader) || showUsersWithOutFollowers && viewModel.isAllUsersFetching) ? 1 : 0)
        )
        .fullScreenCover(isPresented: self.$showUsersWithOutFollowersModal) {
            CBZChatFriendsView(store: store, loggedInUser: viewModel.loggedInUser, viewer: viewer, showUsersWithOutFollowers: true, appConfig: appConfig, uiConfig: uiConfig)
                .onAppear {
                    viewModel.isChatFriendsVisible = false
                }
                .onDisappear {
                    viewModel.isChatFriendsVisible = true
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
