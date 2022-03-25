//
//  CBZNotificationsView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/05/21.
//

import SwiftUI

struct CBZNotificationsView: View {
    var viewer: ATCUser?
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @ObservedObject private var viewModel = CBZNotificationsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack() {
                if !viewModel.showLoader {
                    if viewModel.notifications.count == 0 {
                        CBZEmptyView(title: "No Notifications".localizedFeed, subTitle: "You currently do not have any notifications. Your notifications will show up here.".localizedFeed, buttonTitle: "", hideButton: true, appConfig: appConfig, uiConfig: uiConfig)
                            .padding(.top, 50)
                    }
                    LazyVStack {
                        ForEach(viewModel.notifications) { notification in
                            CBZNotificationView(notification: notification, appConfig: appConfig, uiConfig: uiConfig)
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
            .opacity(viewModel.showLoader ? 1 : 0)
        )
        .onAppear {
            self.viewModel.fetchNotifications(loggedInUser: viewer)
        }
        .navigationBarTitle("Notifications".localizedFeed, displayMode: .inline)
    }
}
