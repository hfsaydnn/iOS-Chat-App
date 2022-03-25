//
//  CBZForgotPasswordScreen.swift
//  SCore
//
//  Created by Mayil Kannan on 02/04/21.
//

import SwiftUI

struct CBZForgotPasswordScreen: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject private var viewModel = CBZForgotPasswordScreenViewModel()

    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    var body: some View {
        VStack {
            HStack {
                Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                    Image("arrow-back-icon")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                }
                .padding(.top, 10)
                .padding(.leading, 10)
                Spacer()
            }
            
            HStack {
                Text("Reset Password".localizedCore)
                    .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                    .font(uiConfig.boldSuperLargeFont)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                Spacer()
            }
            
            HStack {
                TextField("E-mail".localizedCore, text: $viewModel.email)
                    .padding()
            }
            .frame(height: 42)
            .frame(minWidth: 0, maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 42/2)
                    .stroke(Color(uiConfig.grey3), lineWidth: 1)
            )
            .padding(.horizontal, 35)
            .padding(.top, 50)
            
            Button(action: {
                viewModel.didTapResetPasswordButton()
            }) {
                Text("Reset My Password".localizedCore)
                   .frame(maxWidth: .infinity, maxHeight: .infinity)
                   .contentShape(Rectangle())
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 45)
            .foregroundColor(Color.white)
            .background(Color(uiConfig.mainThemeForegroundColor))
            .cornerRadius(45/2)
            .padding(.horizontal, 50)
            .padding(.top, 30)
            
            Spacer()
        }
        .navigationBarHidden(true)
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showProgress ? 1 : 0)
        )
        .alert(isPresented: $viewModel.shouldShowAlert) { () -> Alert in
            Alert(title: Text(viewModel.alertMessage),
                  dismissButton: .default (Text("OK".localizedCore)) {
                    if viewModel.shouldDismissView {
                        self.presentationMode.wrappedValue.dismiss()
                    }
              })
        }
    }
}
