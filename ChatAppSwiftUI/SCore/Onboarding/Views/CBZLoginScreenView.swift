//
//  CBZLoginScreenView.swift
//  SCore
//
//  Created by Mayil Kannan on 09/03/21.
//

import SwiftUI
import AuthenticationServices

struct CBZLoginScreenView: View {

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject private var viewModel: CBZLoginScreenViewModel
    @ObservedObject var store: CBZPersistentStore
    @State private var showingCountryPicker = false
    @State private var showingSheet: Bool = false

    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    
    init(store: CBZPersistentStore, appRootScreenViewModel: AppRootScreenViewModel, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = CBZLoginScreenViewModel(store: store, appRootScreenViewModel: appRootScreenViewModel, appConfig: appConfig)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
                    Text("Sign In".localizedCore)
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                        .font(uiConfig.boldSuperLargeFont)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                    Spacer()
                }
                
                if viewModel.isPhoneAuthEnabled {
                    if !viewModel.isCodeSend {
                        HStack {
                            Button(action: {
                                showingCountryPicker.toggle()
                                showingSheet.toggle()
                            }) {
                                Image(viewModel.phoneCountryCodeString)
                                    .resizable()
                                    .cornerRadius(42/2, corners: [.topLeft, .bottomLeft])
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 42, height: 42)
                                    .padding(.leading, 10)
                            }
                            Divider()
                            TextField("Phone number".localizedCore, text: $viewModel.phoneNumber)
                            Spacer()
                        }
                        .frame(height: 42)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 42/2)
                                .stroke(Color(uiConfig.grey3), lineWidth: 1)
                        )
                        .padding(.horizontal, 35)
                        .padding(.top, 50)
                    } else {
                        CBZPasscodeField(verificationCode: $viewModel.verificationCode) { (text, completion) in }
                            .frame(height: 42)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(.horizontal, 35)
                            .padding(.top, 50)
                    }
                } else {
                    HStack {
                        TextField("E-mail".localizedCore, text: $viewModel.email)
                            .autocapitalization(.none)
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
                    
                    HStack {
                        SecureField("Password".localizedCore, text: $viewModel.password)
                            .padding()
                    }
                    .frame(height: 42)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 42/2)
                            .stroke(Color(uiConfig.grey3), lineWidth: 1)
                    )
                    .padding(.horizontal, 35)
                    .padding(.top, 10)
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: CBZForgotPasswordScreen(appConfig: appConfig, uiConfig: uiConfig)) {
                            Text("Forgot password?".localizedChat)
                        }
                    }
                    .frame(height: 42)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                Button(action: {
                    viewModel.didTapLoginButton()
                }) {
                    Text((viewModel.isPhoneAuthEnabled ? (!viewModel.isCodeSend ? "Send code" : "Submit code") : "Log In").localizedCore)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 45)
                .foregroundColor(Color.white)
                .background(Color(uiConfig.mainThemeForegroundColor))
                .cornerRadius(45/2)
                .padding(.horizontal, 50)
                .padding(.top, 20)
                
                Text("OR".localizedCore)
                    .padding(.top, 30)
                
                Button("Login with Facebook".localizedChat) {
                    viewModel.didTapFacebookButton()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 45)
                .foregroundColor(Color.white)
                .background(Color(UIColor(hexString: "#334D92")))
                .cornerRadius(45/2)
                .padding(.horizontal, 50)
                .padding(.top, 30)
                
                AppleSignInButton()
                    .frame(height: 45)
                    .cornerRadius(45/2)
                    .padding(.horizontal, 50)
                    .padding(.top, 10)
                    .onTapGesture {
                        viewModel.handleAuthorizationAppleIDButtonPress()
                    }
                
                Button((viewModel.isPhoneAuthEnabled ? "Sign in with E-mail" : "Login with phone number").localizedCore) {
                    viewModel.isPhoneAuthEnabled.toggle()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 45)
                .padding(.horizontal, 50)
                .padding(.top, 10)
                
                Spacer()
            }
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
            Alert(title: Text(viewModel.alertMessage))
        }
        .sheet(isPresented: $showingSheet) {
            CBZCountryCodePickerView(phoneCountryCodeString: $viewModel.phoneCountryCodeString,
                                  phoneCodeString: $viewModel.phoneCodeString,
                                  showingCountryPicker: $showingCountryPicker,
                                  showingSheet: $showingSheet)
        }
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct AppleSignInButton: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton(authorizationButtonType: .signIn,
                                            authorizationButtonStyle: UITraitCollection.current.userInterfaceStyle == .dark ? .white : .black)
        
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context:
                        Context) {
    }
}
