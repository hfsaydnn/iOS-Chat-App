//
//  CBZSignUpScreenView.swift
//  SCore
//
//  Created by Mayil Kannan on 09/03/21.
//

import SwiftUI

struct CBZSignUpScreenView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject private var viewModel: CBZSignUpScreenViewModel
    @ObservedObject var store: CBZPersistentStore
    @State private var showingSheet: Bool = false
    @State private var showingCountryPicker = false
    
    @State var showAction: Bool = false
    @State var showImagePicker: Bool = false

    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    init(store: CBZPersistentStore, appRootScreenViewModel: AppRootScreenViewModel, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = CBZSignUpScreenViewModel(store: store, appRootScreenViewModel: appRootScreenViewModel)
    }
    
    var sheet1: ActionSheet {
        ActionSheet(
            title: Text("Change Photo".localizedFeed),
            message: Text("Change your profile photo".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.showAction = false
                    self.showImagePicker = true
                    self.showingSheet = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.showAction = false
                    self.showImagePicker = true
                    self.showingSheet = true
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.showAction = false
                })
            ])
    }
    
    var sheet2: ActionSheet {
        ActionSheet(
            title: Text("Change Photo".localizedFeed),
            message: Text("Change your profile photo".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.showAction = false
                    self.showImagePicker = true
                    self.showingSheet = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.showAction = false
                    self.showImagePicker = true
                    self.showingSheet = true
                }),
                .destructive(Text("Remove Photo".localizedFeed), action: {
                    self.showAction = false
                    self.viewModel.uiImage = nil
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.showAction = false
                })
            ])
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
                    Text("Create new account".localizedCore)
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                        .font(uiConfig.boldSuperLargeFont)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                    Spacer()
                }
                ZStack {
                    if (viewModel.uiImage == nil) {
                        Image("empty-avatar")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(uiImage: viewModel.uiImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                    ZStack {
                        Image("")
                            .resizable()
                            .background(Color(UIColor(hexString: "#DCDCDC")))
                            .opacity(0.8)
                        Image("camera-filled-icon")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .clipShape(Circle())
                    .frame(width: 30, height: 30)
                    .padding(.top, 80)
                    .padding(.leading, 60)
                }
                .padding(.top, 10)
                .onTapGesture {
                    self.showAction = true
                }
                
                HStack {
                    TextField("First Name".localizedCore, text: $viewModel.firtName)
                        .padding()
                }
                .frame(height: 42)
                .frame(minWidth: 0, maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 42/2)
                        .stroke(Color(uiConfig.grey3), lineWidth: 1)
                )
                .padding(.horizontal, 35)
                .padding(.top, 30)
                
                HStack {
                    TextField("Last Name".localizedCore, text: $viewModel.lastName)
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
                        .padding(.top, 10)
                    } else {
                        CBZPasscodeField(verificationCode: $viewModel.verificationCode) { (text, completion) in }
                            .frame(height: 42)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(.horizontal, 35)
                            .padding(.top, 10)
                    }
                } else {
                    HStack {
                        TextField("E-mail".localizedCore, text: $viewModel.email)
                            .keyboardType(.emailAddress)
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
                    .padding(.top, 10)
                    
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
                }
                
                Button(action: {
                    viewModel.didTapSignUpButton()
                }) {
                    Text((viewModel.isPhoneAuthEnabled ? (!viewModel.isCodeSend ? "Send code" : "Submit code") : "Sign up").localizedCore)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 45)
                .foregroundColor(Color.white)
                .background(Color(uiConfig.mainThemeForegroundColor))
                .cornerRadius(45/2)
                .padding(.horizontal, 50)
                .padding(.top, 30)
                
                Text("OR".localizedCore)
                    .padding(.top, 30)
                
                Button((viewModel.isPhoneAuthEnabled ? "Sign up with E-mail" : "Sign up with phone number").localizedCore) {
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
        .sheet(isPresented: $showingSheet, onDismiss: {
            if showImagePicker {
                showImagePicker = false
            } else if showingCountryPicker {
                showingCountryPicker = false
            }
            showingSheet = false
        }, content: {
            if showImagePicker {
                CBZImagePicker(isShown: self.$showImagePicker, isShownSheet: self.$showingSheet) { (image, url) in
                    if let image = image {
                        self.viewModel.uiImage = image
                    }
                }
            } else if showingCountryPicker {
                CBZCountryCodePickerView(phoneCountryCodeString: $viewModel.phoneCountryCodeString,
                                      phoneCodeString: $viewModel.phoneCodeString,
                                      showingCountryPicker: $showingCountryPicker,
                                      showingSheet: $showingSheet)
            }
        })
        .actionSheet(isPresented: $showAction) {
            if viewModel.uiImage == nil {
                return sheet1
            } else {
                return sheet2
            }
        }
    }
}
