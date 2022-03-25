//
//  CBZConversationsView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 24/04/21.
//

import SwiftUI

struct CBZConversationsView: View {
    @ObservedObject var store: CBZPersistentStore
    var viewer: ATCUser? = nil
    @ObservedObject private var viewModel:CBZConversationsViewModel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @Binding var tabSelection: Int

    init(store: CBZPersistentStore, viewer: ATCUser?, tabSelection: Binding<Int>, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = CBZConversationsViewModel(user: viewer)
        self._tabSelection = tabSelection
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack() {
                    if !viewModel.showLoader {
                        if viewModel.channels.count == 0 {
                            CBZEmptyView(title: "No Conversations".localizedChat, subTitle: "Start chatting with the people you follow. Your conversations will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, uiConfig: uiConfig, completionHandler: {
                                tabSelection = 3
                            })
                                .padding(.top, 50)
                        }
                        LazyVStack {
                            ForEach(viewModel.channels) { channel in
                                CBZConversationView(channel: channel, viewer: viewer, appConfig: appConfig, uiConfig: uiConfig, conversationViewModel: viewModel)
                            }
                        }
                    }
                    Spacer()
                }.id(viewModel.updatingTime)
            }
            .overlay(
                VStack {
                    CPKProgressHUDSwiftUI()
                }
                .frame(width: 100,
                       height: 100)
                .opacity(viewModel.showLoader ? 1 : 0)
            )
            .navigationBarTitle("Messages".localizedCore, displayMode: .inline)
            .navigationBarItems(trailing:
                                    NavigationLink(destination: CBZChatGroupMembersView(viewer: viewer, appConfig: appConfig, uiConfig: uiConfig)) {
                                        Image("inscription")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(Color(uiConfig.mainTextColor))
                                    }
            )
        }
    }
}
