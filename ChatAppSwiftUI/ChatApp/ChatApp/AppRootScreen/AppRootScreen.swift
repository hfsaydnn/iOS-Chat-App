//
//  AppRootScreen.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 08/03/21.
//

import SwiftUI

struct AppRootScreen: View {

    @ObservedObject var store: CBZPersistentStore
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @ObservedObject private var viewModel: AppRootScreenViewModel
    @State private var selection = 0
    
    var landingScreenView: some View {
        CBZLandingScreenView(store: store,
                             appRootScreenViewModel: self.viewModel,
                             appConfig: appConfig,
                             uiConfig: uiConfig,
                             welcomeTitle: "Instachatty".localizedFeed,
                             welcomeDescription: "Send texts, photos, videos, and audio messages to your close friends.".localizedFeed)
    }
    
    init(store: CBZPersistentStore, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = AppRootScreenViewModel(store: store, appConfig: appConfig)
    }
    
    var body: some View {
        Group {
            if !store.isWalkthroughCompleted() {
                CBZWalkthoughView(store: store, walkthroughData: appConfig.walkthroughData, appConfig: appConfig, uiConfig: uiConfig)
            } else if let loggedInUser = store.userIfLoggedInUser() {
                if viewModel.resyncSuccess {
                    TabView(selection: $selection) {
                        CBZChatHomeView(store: store, loggedInUser: viewModel.viewer, viewer: viewModel.viewer, appConfig: appConfig, uiConfig: uiConfig)
                            .tabItem {
                                CBZConversationsTabItem(uiConfig: uiConfig, selection: $selection)
                            }
                            .tag(2)
                        CBZChatFriendsView(store: store, loggedInUser: viewModel.viewer, viewer: viewModel.viewer, appConfig: appConfig, uiConfig: uiConfig)
                            .tabItem {
                                CBZFriendsTabItem(uiConfig: uiConfig, selection: $selection)
                            }
                            .tag(3)
                        CBZChatProfileView(store: store, loggedInUser: viewModel.viewer, viewer: viewModel.viewer, hideNavigationBar: false, appConfig: appConfig, uiConfig: uiConfig)
                            .tabItem {
                                CBZProfileTabItem(uiConfig: uiConfig, selection: $selection)
                            }
                            .tag(4)
                    }
                } else if viewModel.resyncCompleted {
                    landingScreenView
                }
            } else {
                landingScreenView
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showProgress ? 1 : 0)
        )
        .onAppear {
            self.viewModel.resyncPersistentCredentials()
        }
    }
}

struct CBZFeedTabItem: View {
    var uiConfig: CBZUIConfigurationProtocol
    @Binding var selection: Int
    
    var body: some View {
        if selection == 0 {
            Image("home-filled")
                .configTabItemImage(isSelected: true, uiConfig: uiConfig)
        } else {
            Image("home-unfilled")
                .configTabItemImage(isSelected: false, uiConfig: uiConfig)
        }
    }
}

struct CBZDiscoverTabItem: View {
    var uiConfig: CBZUIConfigurationProtocol
    @Binding var selection: Int
    
    var body: some View {
        if selection == 1 {
            Image("search")
                .configTabItemImage(isSelected: true, uiConfig: uiConfig)
        } else {
            Image("search")
                .configTabItemImage(isSelected: false, uiConfig: uiConfig)
        }
    }
}

struct CBZConversationsTabItem: View {
    var uiConfig: CBZUIConfigurationProtocol
    @Binding var selection: Int
    
    var body: some View {
        if selection == 2 {
            Image("chat-filled")
                .configTabItemImage(isSelected: true, uiConfig: uiConfig)
        } else {
            Image("chat-unfilled")
                .configTabItemImage(isSelected: false, uiConfig: uiConfig)
        }
    }
}

struct CBZFriendsTabItem: View {
    var uiConfig: CBZUIConfigurationProtocol
    @Binding var selection: Int
    
    var body: some View {
        if selection == 3 {
            Image("friends-filled")
                .configTabItemImage(isSelected: true, uiConfig: uiConfig)
        } else {
            Image("friends-unfilled")
                .configTabItemImage(isSelected: false, uiConfig: uiConfig)
        }
    }
}

struct CBZProfileTabItem: View {
    var uiConfig: CBZUIConfigurationProtocol
    @Binding var selection: Int
    
    var body: some View {
        if selection == 4 {
            Image("profile-filled")
                .configTabItemImage(isSelected: true, uiConfig: uiConfig)
        } else {
            Image("profile-unfilled")
                .configTabItemImage(isSelected: false, uiConfig: uiConfig)
        }
    }
}

extension Image {
    func configTabItemImage(isSelected: Bool, uiConfig: CBZUIConfigurationProtocol) -> some View {
        if isSelected {
            return self
                .renderingMode(.template)
                .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
        } else {
            return self
                .renderingMode(.template)
                .foregroundColor(Color(uiConfig.mainTextColor))
        }
    }
}
