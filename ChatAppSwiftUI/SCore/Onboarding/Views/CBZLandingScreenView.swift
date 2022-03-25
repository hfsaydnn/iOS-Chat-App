//
//  CBZLandingScreenView.swift
//  SCore
//
//  Created by Mayil Kannan on 09/03/21.
//

import SwiftUI

struct CBZLandingScreenView: View {
    
    @ObservedObject var store: CBZPersistentStore
    @ObservedObject var appRootScreenViewModel: AppRootScreenViewModel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    let welcomeTitle: String
    let welcomeDescription: String

    var body: some View {
        NavigationView {
            VStack() {
                Image("app-logo")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                Text(welcomeTitle)
                    .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                    .font(uiConfig.boldSuperLargeFont)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                Text(welcomeDescription)
                    .foregroundColor(Color(uiConfig.mainTextColor))
                    .font(uiConfig.regularFont(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                NavigationLink(destination: CBZLoginScreenView(store: store, appRootScreenViewModel: appRootScreenViewModel, appConfig: appConfig, uiConfig: uiConfig)) {
                    Text("Log In".localizedCore)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundColor(Color.white)
                        .background(Color(uiConfig.mainThemeForegroundColor))
                        .cornerRadius(45/2)
                        .padding(.horizontal, 50)
                        .padding(.top, 30)
                }
                NavigationLink(destination: CBZSignUpScreenView(store: store, appRootScreenViewModel: appRootScreenViewModel, appConfig: appConfig, uiConfig: uiConfig)) {
                    Text("Sign Up".localizedCore)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 45/2)
                                .stroke(Color(uiConfig.mainThemeForegroundColor), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 50)
                        .padding(.top, 10)
                }
            }.offset(y: -50)
        }
    }
}
