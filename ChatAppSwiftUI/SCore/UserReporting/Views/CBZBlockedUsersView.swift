//
//  CBZBlockedUsersView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 30/05/21.
//

import SwiftUI

struct CBZBlockedUsersView: View {
    @ObservedObject var viewModel: CBZBlockedUserViewModel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    init(loggedInUser: ATCUser?, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.viewModel = CBZBlockedUserViewModel(loggedInUser: loggedInUser)
        self.appConfig = appConfig
        self.uiConfig = uiConfig
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                if !viewModel.isBlockedUsersFetching {
                    if viewModel.blockedUsers.count == 0 {
                        CBZEmptyView(title: "No Blocked Users".localizedFeed, subTitle: "You haven't blocked nor reported anyone yet. The users that you block or report will show up here.".localizedFeed, buttonTitle: "", hideButton: true, appConfig: appConfig, uiConfig: uiConfig)
                            .padding(.top, 50)
                    }
                    LazyVStack {
                        ForEach(viewModel.blockedUsers, id: \.self) { user in
                            CBZBlockedUserView(viewModel: viewModel, blockedUser: user, appConfig: appConfig, uiConfig: uiConfig)
                        }
                    }
                }
                Spacer()
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.isBlockedUsersFetching ? 1 : 0)
        )
        .onAppear {
            if !self.viewModel.isBlockedUsersFetching {
                self.viewModel.fetchBlockedUsers()
            }
        }
        .navigationBarTitle("Blocked Users".localizedFeed, displayMode: .inline)
    }
}
