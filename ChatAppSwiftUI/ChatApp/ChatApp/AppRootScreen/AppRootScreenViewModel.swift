//
//  AppRootScreenViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 08/04/21.
//

import SwiftUI
import LocalAuthentication

class AppRootScreenViewModel: ObservableObject {
 
    @Published var showProgress: Bool = false
    @Published var resyncSuccess: Bool = false {
        didSet {
            if resyncSuccess {
                registerForPushNotifications()
            }
        }
    }
    @Published var resyncCompleted: Bool = false
    @ObservedObject var store: CBZPersistentStore
    let userManager: ATCSocialUserManagerProtocol?
    var viewer: ATCUser? = nil
    let faceIDKey = "face_id_enabled"
    var userStatus: Bool = false
    var appConfig: CBZConfigurationProtocol
    
    init(store: CBZPersistentStore, appConfig: CBZConfigurationProtocol) {
        self.store = store
        self.appConfig = appConfig
        self.userManager = ATCSocialFirebaseUserManager()
    }
    
    func resyncPersistentCredentials() {
        if let loggedInUser = store.userIfLoggedInUser() {
            let result = UserDefaults.standard.value(forKey: "\(loggedInUser.uid!)")
            if let finalResult = result as? [String : Bool] {
                userStatus = finalResult[faceIDKey] ?? false
            }
            if userStatus {
                self.biometricAuthentication(user: loggedInUser)
            } else {
                self.startResyncPersistentUser(user: loggedInUser)
            }
        }
    }
    
    private func startResyncPersistentUser(user: ATCUser) {
        showProgress = true
        self.resyncPersistentUser(user: user) {[weak self] (syncedUser, error) in
            self?.showProgress = false
            if let syncedUser = syncedUser {
                self?.viewer = syncedUser
                self?.resyncSuccess = true
            } else {
                self?.resyncSuccess = false
            }
            self?.resyncCompleted = true
        }
    }
    
    private func biometricAuthentication(user: ATCUser) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify Yourself"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [unowned self] (success, error) in
                DispatchQueue.main.async {
                    if success {
                        print("Successfully match")
                        self.startResyncPersistentUser(user: user)
                    }else {
                        print("Error - not a successful match - Log in using password")
                        self.resyncSuccess = false
                        self.resyncCompleted = true
                    }
                }
            }
        } else {
            print("No Biometric Auth support")
            self.startResyncPersistentUser(user: user)
        }
    }
    
    func resyncPersistentUser(user: ATCUser, completionBlock: @escaping (_ user: ATCUser?, _ error: Error?) -> Void) {
        if let uid = user.uid {
            self.userManager?.fetchUser(userID: uid) { (newUser, error) in
                if let newUser = newUser {
                    completionBlock(newUser, error)
                } else {
                    // User is no longer existing
                    if let email = user.email, user.uid == email {
                        // We don't log out Apple Signed in users
                        completionBlock(user, error)
                        return
                    }
                    completionBlock(nil, error)
                }
            }
        }
    }
    
    func registerForPushNotifications() {
        if let loggedInUser = store.userIfLoggedInUser() {
            let pushManager = ATCPushNotificationManager(user: loggedInUser)
            pushManager.registerForPushNotifications()
        }
    }
}
