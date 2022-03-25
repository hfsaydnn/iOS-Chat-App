//
//  CBZSignUpScreenViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 06/04/21.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

let kUserSignUpNotificationName = NSNotification.Name(rawValue: "kUserSignUpNotificationName")

class CBZSignUpScreenViewModel: ObservableObject {
    
    @Published var phoneCountryCodeString: String = "US"
    @Published var phoneCodeString: String = "+1"
    @Published var verificationCode: String = ""
    @Published var phoneNumber: String = ""
    @Published var firtName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPhoneAuthEnabled: Bool = true
    @Published var isCodeSend: Bool = false
    @Published var showProgress: Bool = false
    @Published var shouldShowAlert = false
    @Published var alertMessage: String = ""
    @Published var uiImage: UIImage? = nil
    @ObservedObject var store: CBZPersistentStore
    @ObservedObject private var appRootScreenViewModel: AppRootScreenViewModel
    let profileFirebaseUpdater: ATCProfileFirebaseUpdater
    
    init(store: CBZPersistentStore, appRootScreenViewModel: AppRootScreenViewModel) {
        self.store = store
        self.profileFirebaseUpdater = ATCProfileFirebaseUpdater(usersTable: "users")
        self.appRootScreenViewModel = appRootScreenViewModel
    }
    
    @objc func didTapSignUpButton() {
        ATCHapticsFeedbackGenerator.generateHapticFeedback(.mediumImpact)
        
        if isPhoneAuthEnabled && isCodeSend {
            if !verificationCode.isEmpty {
                showProgress = true
                let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") ?? ""
                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID,
                    verificationCode: verificationCode)
                Auth.auth().signIn(with: credential) {[weak self] (dataResult, error) in
                    if let strongSelf = self, let user = dataResult?.user {
                        let user = ATCUser(uid: user.uid,
                                           firstName: user.displayName ?? self?.firtName,
                                           lastName: user.displayName ?? self?.lastName,
                                           avatarURL: user.photoURL?.absoluteString ?? "",
                                           email: user.email ?? "",
                                           phoneNumber: user.phoneNumber ?? "")
                        if let uiImage = strongSelf.uiImage {
                            strongSelf.profileFirebaseUpdater.uploadPhoto(image: uiImage, user: user, isProfilePhoto: true) {[weak self] (success) in
                                strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "instagram-swiftui-ios")
                                if let strongSelf = self {
                                    strongSelf.store.markUserAsLoggedIn(user: user)
                                    strongSelf.appRootScreenViewModel.resyncCompleted = false
                                    strongSelf.appRootScreenViewModel.resyncSuccess = false
                                    strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                                    NotificationCenter.default.post(name: kUserSignUpNotificationName, object: nil, userInfo: nil)
                                }
                                self?.showProgress = false
                            }
                        } else {
                            strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "instagram-swiftui-ios")
                            if let strongSelf = self {
                                strongSelf.store.markUserAsLoggedIn(user: user)
                                strongSelf.appRootScreenViewModel.resyncCompleted = false
                                strongSelf.appRootScreenViewModel.resyncSuccess = false
                                strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                                NotificationCenter.default.post(name: kUserSignUpNotificationName, object: nil, userInfo: nil)
                            }
                            self?.showProgress = false
                        }
                    } else if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                        self?.showProgress = false
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                        self?.showProgress = false
                    }
                }
            } else {
                self.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                self.shouldShowAlert = true
            }
            return
        } else if isPhoneAuthEnabled {
            if !phoneNumber.isEmpty {
                showProgress = true
                PhoneAuthProvider.provider().verifyPhoneNumber(phoneCodeString + phoneNumber, uiDelegate: nil) {[weak self] (verificationID, error) in
                    self?.showProgress = false
                    if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                    } else {
                        UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                        self?.isCodeSend = true
                    }
                }
            } else {
                self.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                self.shouldShowAlert = true
            }
            return
        } else {
            if !email.isEmpty, !password.isEmpty {
                showProgress = true
                Auth.auth().createUser(withEmail: email, password: password) {[weak self] (dataResult, error) in
                    if let strongSelf = self, let user = dataResult?.user {
                        let user = ATCUser(uid: user.uid,
                                           firstName: user.displayName ?? self?.firtName,
                                           lastName: user.displayName ?? self?.lastName,
                                           avatarURL: user.photoURL?.absoluteString ?? "",
                                           email: user.email ?? "")
                        if let uiImage = strongSelf.uiImage {
                            strongSelf.profileFirebaseUpdater.uploadPhoto(image: uiImage, user: user, isProfilePhoto: true) {[weak self] (success) in
                                strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "instagram-swiftui-ios")
                                if let strongSelf = self {
                                    strongSelf.store.markUserAsLoggedIn(user: user)
                                    strongSelf.appRootScreenViewModel.resyncCompleted = false
                                    strongSelf.appRootScreenViewModel.resyncSuccess = false
                                    strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                                    NotificationCenter.default.post(name: kUserSignUpNotificationName, object: nil, userInfo: nil)
                                }
                                self?.showProgress = false
                            }
                        } else {
                            strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "instagram-swiftui-ios")
                            if let strongSelf = self {
                                strongSelf.store.markUserAsLoggedIn(user: user)
                                strongSelf.appRootScreenViewModel.resyncCompleted = false
                                strongSelf.appRootScreenViewModel.resyncSuccess = false
                                strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                                NotificationCenter.default.post(name: kUserSignUpNotificationName, object: nil, userInfo: nil)
                            }
                            self?.showProgress = false
                        }
                    } else if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                        self?.showProgress = false
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                        self?.showProgress = false
                    }
                }
            } else {
                self.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                self.shouldShowAlert = true
            }
            return
        }
    }
    
    func saveUserToServerIfNeeded(user: ATCUser, appIdentifier: String) {
        let ref = Firestore.firestore().collection("users")
        if let uid = user.uid {
            var dict = user.representation
            dict["appIdentifier"] = appIdentifier
            ref.document(uid).setData(dict, merge: true)
        }
    }
}
