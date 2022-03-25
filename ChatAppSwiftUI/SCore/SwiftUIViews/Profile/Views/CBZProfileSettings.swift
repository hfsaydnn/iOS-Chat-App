//
//  CBZProfileSettings.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 12/05/21.
//

import SwiftUI

enum CBZProfileSettingsType {
    case accountDetails
    case blockedUsers
    case settings
    case contactUs
    case none
}

struct CBZProfileSettings: View {
    @ObservedObject var viewModel: CBZProfileViewModel
    @ObservedObject var store: CBZPersistentStore
    @State var isNavigationActive: Bool?
    @State var profileSettings: CBZProfileSettingsType = .none
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    var title: String
    
    init(viewModel: CBZProfileViewModel, store: CBZPersistentStore, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol, title: String = "General".localizedFeed, clearBackground: Bool = false){
        self.viewModel = viewModel
        self.store = store
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.title = title
        if clearBackground {
            UITableView.appearance().backgroundColor = .clear
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text(title)) {
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .accountDetails
                }) {
                    HStack {
                        Spacer()
                        Text("Account Details".localizedFeed)
                        Spacer()
                    }
                }
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .blockedUsers
                }) {
                    HStack {
                        Spacer()
                        Text("Blocked Users".localizedFeed)
                        Spacer()
                    }
                }
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .settings
                }) {
                    HStack {
                        Spacer()
                        Text("Settings".localizedFeed)
                        Spacer()
                    }
                }
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .contactUs
                }) {
                    HStack {
                        Spacer()
                        Text("Contact Us".localizedCore)
                        Spacer()
                    }
                }
                Button(action: {
                    self.store.logout()
                }) {
                    HStack {
                        Spacer()
                        Text("Log Out".localizedFeed)
                        Spacer()
                    }
                }
            }
        }.navigationBarTitle("Profile Settings".localizedFeed)
        .navigate(using: $isNavigationActive, destination: makeDestination)
    }
    
    @ViewBuilder
    private func makeDestination(for isNavigationActive: Bool) -> some View {
        switch profileSettings {
        case .accountDetails:
            CBZEditProfileView(viewModel: viewModel)
        case .blockedUsers:
            CBZBlockedUsersView(loggedInUser: viewModel.loggedInUser, appConfig: appConfig, uiConfig: uiConfig)
        case .settings:
            CBZUserSettings(viewModel: viewModel)
        case .contactUs:
            CBZContactUsView(uiConfig: uiConfig)
        case .none:
            EmptyView()
        }
    }
}


