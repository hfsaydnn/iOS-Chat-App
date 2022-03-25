//
//  CBZDatingProfileViewModel.swift
//  DatingApp
//
//  Created by Mayil Kannan on 15/08/21.
//

import SwiftUI
import FirebaseFirestore

class CBZDatingProfileViewModel: ObservableObject {

    @Published var isPostFetching: Bool = false
    var viewer: CBZDatingProfile? = nil
    var loggedInUser: CBZDatingProfile? = nil
    @Published var showLoader: Bool = false
    var pushNotificationManager: ATCPushNotificationManager?
    private let defaults = UserDefaults.standard
    let profileFirebaseUpdater: ATCProfileFirebaseUpdater = ATCProfileFirebaseUpdater(usersTable: "users")
    @Published var isProfileImageUpdated: Bool = false
    @Published var uiImage: UIImage? = nil {
        didSet {
            if let uiImage = uiImage {
                isProfileImageUpdated = true
                self.updateProfileImage(image: uiImage)
            }
        }
    }
    @Published var shouldShowAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    var isLoggedInUser: Bool = false
    var profileUpdater = ATCProfileFirebaseUpdater(usersTable: "users")
    var userPhotos: [[String]] = []
    @Published var userPhotosUpdated = Date()
    @Published var profilePictureUpdated = Date()

    @Published var sections: [CBZSettingSection] = []
    
    init(loggedInUser: CBZDatingProfile?, viewer: CBZDatingProfile?) {
        self.loggedInUser = loggedInUser
        self.viewer = viewer
        if let viewer = viewer, viewer.uid != loggedInUser?.uid {
            self.isLoggedInUser = false
        } else {
            self.isLoggedInUser = true
        }
        userPhotos = fetchUserPhotos(user: viewer) ?? []
    }
    
    private func fetchUserPhotos(user: ATCUser?) -> [[String]]? {
        var photos: [[String]] = []
        var lastIndex = 0
        if let photos1 = user?.photos {
            for photo in photos1 {
                if photos.count == lastIndex {
                    photos.insert([photo], at: lastIndex)
                } else if photos[lastIndex].count < 5 {
                    photos[lastIndex].append(photo)
                } else {
                    photos[lastIndex].append(photo)
                    lastIndex += 1
                }
            }
        }
        if photos.count == 0 {
            photos.insert(["photo"], at: 0)
        } else if let lastPhotos = photos.last, lastPhotos.count < 6 {
            photos[photos.count-1].append("photo")
        } else {
            photos.insert(["photo"], at: photos.count)
        }
        return photos
    }
        
    func update(email: String, firstName: String, lastName: String, phone: String, age: String, bio: String, school: String, completion: @escaping () -> Void) {
        showLoader = true
        let documentRef = Firestore.firestore().collection("users").document("\(loggedInUser?.uid ?? "0")")
        documentRef.setData([
            "firstName" : firstName,
            "lastName"  : lastName,
            "email"     : email,
            "phone"     : phone,
            "age": age,
            "bio": bio,
            "school": school
        ], merge: true) { err in
            self.showLoader = false
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Successfully updated")
                self.loggedInUser?.firstName = firstName
                self.loggedInUser?.lastName = lastName
                self.loggedInUser?.email = email
                self.loggedInUser?.phoneNumber = phone
                self.loggedInUser?.age = age
                self.loggedInUser?.bio = bio
                self.loggedInUser?.school = school
                completion()
            }
        }
    }
    
    func updateSettings(userSettingsJSON: [String : Any], isPushNotificationsEnabled: Bool, completion: @escaping () -> Void) {
        showLoader = true
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        let usersRef = Firestore.firestore().collection("users").document("\(loggedInUser?.uid ?? "0")")
        usersRef.setData(userSettingsJSON, merge: true) { [weak self] (error) in
            guard let self = self else { return }
            self.showLoader = false
            if error == nil {
                if isPushNotificationsEnabled {
                    self.pushNotificationManager?.updateFirestorePushTokenIfNeeded()
                } else {
                    self.pushNotificationManager?.removeFirestorePushTokenIfNeeded()
                }
                self.defaults.set(userSettingsJSON, forKey: "\(self.loggedInUser?.uid ?? "0")")
                for section in self.sections {
                    for option in section.options {
                        if option.isBoolType {
                            self.loggedInUser?.settings[option.key] = option.isToggleOn
                        } else {
                            self.loggedInUser?.settings[option.key] = option.settingValue
                        }
                    }
                }
                completion()
            }
        }
    }
    
    func updateProfileImage(image: UIImage) {
        guard let user = loggedInUser else { return }
        showLoader = true
        profileFirebaseUpdater.uploadPhoto(image: image, user: user, isProfilePhoto: true) {[weak self] (success) in
            self?.showLoader = false
        }
    }
    
    func removePhoto() {
        guard let user = loggedInUser else { return }
        let documentRef = Firestore.firestore().collection("users").document("\(user.uid!)")

        showLoader = true
        documentRef.updateData([
            "profilePictureURL" : FieldValue.delete()
        ]) { [weak self] (error) in
            user.profilePictureURL = ATCUser.defaultAvatarURL
            self?.showLoader = false
        }
    }
    
    func didAddImage(_ image: UIImage) {
        guard let user = loggedInUser else { return }
        showLoader = true
        profileUpdater.uploadPhoto(image: image, user: user, isProfilePhoto: false) { (success) in
            self.showLoader = false
            self.userPhotos = self.fetchUserPhotos(user: user) ?? []
            self.userPhotosUpdated = Date()
        }
    }
    
    func didTapSetAsProfilePicture(urlString: String) {
        guard let user = loggedInUser else { return }
        showLoader = true
        profileUpdater.updateProfilePicture(url: urlString, user: user) {[weak self] (success) in
            guard let self = self else { return }
            self.showLoader = false
            self.viewer?.profilePictureURL = urlString
            self.profilePictureUpdated = Date()
        }
    }
    
    func didTapRemoveImageButton(urlString: String) {
        guard let user = loggedInUser else { return }
        showLoader = true
        profileUpdater.removePhoto(url: urlString, user: user) {
            self.showLoader = false
            self.userPhotos = self.fetchUserPhotos(user: user) ?? []
            self.userPhotosUpdated = Date()
        }
    }
}
