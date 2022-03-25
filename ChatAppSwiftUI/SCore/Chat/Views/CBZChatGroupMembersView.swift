//
//  CBZChatGroupMembersView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 20/05/21.
//

import SwiftUI

struct CBZChatGroupMembersView: View {
    var viewer: ATCUser? = nil
    @StateObject private var viewModel: CBZChatGroupMembersViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showCreateGroupOption: Double = 0
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    init(viewer: ATCUser?, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol, isChatApp: Bool = false) {
        self.viewer = viewer
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        _viewModel = StateObject(wrappedValue: CBZChatGroupMembersViewModel(isChatApp: isChatApp, viewer: viewer))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack() {
                if !viewModel.showProgress {
                    if viewModel.groupMembers.count < 2 {
                        CBZEmptyView(title: "You can't create groups".localizedChat, subTitle: "You don't have enough friends to create groups. Add at least 2 friends to be able to create groups.".localizedChat, buttonTitle: "Go back".localizedChat, appConfig: appConfig, uiConfig: uiConfig) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        LazyVStack {
                            ForEach(viewModel.groupMembers, id: \.self) { user in
                                CBZChatGroupMemberView(user: user, viewModel: viewModel, showCreateGroupOption: $showCreateGroupOption, appConfig: appConfig, uiConfig: uiConfig)
                            }
                        }
                    }
                }
                Spacer()
            }.padding()
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showProgress ? 1 : 0)
        )
        .navigationBarTitle("Choose People", displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    self.viewModel.createChannel(creator: viewer) { (channel) in
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    Text("Create")
                                }.opacity(showCreateGroupOption)
        )
    }
}
