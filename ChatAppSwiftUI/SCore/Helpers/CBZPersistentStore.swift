//
//  CBZPersistentStore.swift
//  SCore
//
//  Created by Florian Marcu on 8/16/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import Foundation

class CBZPersistentStore: ObservableObject {
    
    private static let kWalkthroughCompletedKey = "kWalkthroughCompletedKey"
    private static let kLoggedInUserKey = "kUserKey"
    @Published var walkthroughCompleted: Bool = false
    @Published var isLogin: Bool = false
    var appConfig: CBZConfigurationProtocol

    init(appConfig: CBZConfigurationProtocol) {
        self.appConfig = appConfig
    }
    
    func markWalkthroughCompleted() {
        UserDefaults.standard.set(true, forKey: CBZPersistentStore.kWalkthroughCompletedKey)
        walkthroughCompleted = true
    }
    
    func isWalkthroughCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: CBZPersistentStore.kWalkthroughCompletedKey)
    }
    
    func markUserAsLoggedIn(user: ATCUser) {
        do {
            let res = try NSKeyedArchiver.archivedData(withRootObject: user, requiringSecureCoding: false)
            UserDefaults.standard.set(res, forKey: CBZPersistentStore.kLoggedInUserKey)
            isLogin = true
        } catch {
            print("Couldn't save due to \(error)")
        }
    }
    
    func userIfLoggedInUser() -> ATCUser? {
        do {
            if let data = UserDefaults.standard.value(forKey: CBZPersistentStore.kLoggedInUserKey) as? Data,
                let user = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ATCUser {
                return user
            }
            return nil
        } catch {
            print("Couldn't load due to \(error)")
            return nil
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: CBZPersistentStore.kLoggedInUserKey)
        isLogin = false
    }
}
