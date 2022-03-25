//
//  CBZDatingProfileView.swift
//  DatingApp
//
//  Created by Mayil Kannan on 15/08/21.
//

import SwiftUI

enum CBZDatingProfileSettingsType {
    case accountDetails
    case upgradeAccount
    case settings
    case contactUs
    case none
}

struct CBZDatingProfileView: View {
    @ObservedObject var store: CBZPersistentStore
    var viewer: CBZDatingProfile? = nil
    @ObservedObject private var viewModel: CBZDatingProfileViewModel
    let userManager = CBZDatingFirebaseUserManager()
    var appConfig: CBZDatingInAppConfigurationProtocol
    @State var isFollowing: Bool?
    @State var isLinkActive = false
    @State var channel: CBZChatChannel?
    var hideNavigationBar: Bool
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showNotification: Bool = false
    @State var showProfileImageAction: Bool = false
    @State var showImagePicker: Bool = false
    @State var showMyPhotoAddImageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var showMyPhotoAddImageAction: Bool = false
    @State var showMyPhotoAddImagePicker: Bool = false
    @State var showMyProfilePicSetImageAction: Bool = false
    @State var myProfilePicSetImageUrlString: String = ""
    @State private var isMediaPickerPresented = false
    @State private var isNewPostPresented = false
    @State var isNavigationActive: Bool?
    @State var profileSettings: CBZDatingProfileSettingsType = .none
    @State private var currentPageIndex = 0
    var uiConfig: CBZUIConfigurationProtocol

    init(store: CBZPersistentStore, loggedInUser: CBZDatingProfile?, viewer: CBZDatingProfile?, isFollowing: Bool? = nil, hideNavigationBar: Bool, appConfig: CBZDatingInAppConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.hideNavigationBar = hideNavigationBar
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewModel = CBZDatingProfileViewModel(loggedInUser: loggedInUser, viewer: viewer)
        self.viewModel.loggedInUser = loggedInUser
        if let loggedInUser = loggedInUser {
            self.viewModel.pushNotificationManager = ATCPushNotificationManager(user: loggedInUser)
        }
    }
    
    var sheet1: ActionSheet {
        ActionSheet(
            title: Text("Change Photo".localizedFeed),
            message: Text("Change your profile photo".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.showImagePicker = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.showImagePicker = true
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.showProfileImageAction = false
                })
            ])
    }
    
    var sheet2: ActionSheet {
        ActionSheet(
            title: Text("Change Photo".localizedFeed),
            message: Text("Change your profile photo".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.showImagePicker = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.showImagePicker = true
                }),
                .destructive(Text("Remove Photo".localizedFeed), action: {
                    self.showProfileImageAction = false
                    self.viewModel.uiImage = nil
                    self.viewModel.isProfileImageUpdated = true
                    self.viewModel.removePhoto()
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.showProfileImageAction = false
                })
            ])
    }
    
    var myPhotoAddImageSheet: ActionSheet {
        ActionSheet(
            title: Text("Add Photo".localizedInApp),
            message: Text(""),
            buttons: [
                .default(Text("Import from Library".localizedInApp), action: {
                    self.showMyPhotoAddImageSourceType = .photoLibrary
                    self.showMyPhotoAddImageAction = false
                    self.showMyPhotoAddImagePicker = true
                }),
                .default(Text("Take Photo".localizedInApp), action: {
                    self.showMyPhotoAddImageSourceType = .camera
                    self.showMyPhotoAddImageAction = false
                    self.showMyPhotoAddImagePicker = true
                }),
                .cancel(Text("Close".localizedCore), action: {
                    self.showMyPhotoAddImageAction = false
                })
            ])
    }
    
    var myProfilePicSetImageSheet: ActionSheet {
        ActionSheet(
            title: Text("Your photo".localizedInApp),
            message: Text(""),
            buttons: [
                .default(Text("Set as Profile Picture".localizedInApp), action: {
                    self.showMyProfilePicSetImageAction = false
                    self.viewModel.didTapSetAsProfilePicture(urlString: myProfilePicSetImageUrlString)
                }),
                .default(Text("Remove".localizedInApp), action: {
                    self.showMyProfilePicSetImageAction = false
                    self.viewModel.didTapRemoveImageButton(urlString: myProfilePicSetImageUrlString)
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.showMyProfilePicSetImageAction = false
                })
            ])
    }
    
    var imageWidth: CGFloat {
        ((UIScreen.main.bounds.width - 20) / 3) - 10
    }
    
    var userPhotosView: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(0..<viewModel.userPhotos.count) { i in
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<viewModel.userPhotos[i].count) { j in
                        if (i == (viewModel.userPhotos.count - 1)) && (j == (viewModel.userPhotos[i].count - 1)) {
                            HStack {
                                Image("camera-filled-icon-large")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30)
                            }
                            .frame(width: imageWidth, height: imageWidth)
                            .background(Color(uiConfig.mainThemeForegroundColor))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showMyPhotoAddImageAction = true
                            }
                        } else {
                            if viewModel.userPhotos[i].count > j && !viewModel.userPhotos[i][j].isEmpty {
                                CBZNetworkImage(imageURL: URL(string: viewModel.userPhotos[i][j])!,
                                                placeholderImage: UIImage(named: "empty-avatar")!,
                                                needUniqueID: true)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: imageWidth, height: imageWidth)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        showMyProfilePicSetImageAction = true
                                        myProfilePicSetImageUrlString = viewModel.userPhotos[i][j]
                                    }
                                    .actionSheet(isPresented: $showMyProfilePicSetImageAction) {
                                        myProfilePicSetImageSheet
                                    }
                            }
                        }
                    }
                }
            }
        }.id(viewModel.userPhotosUpdated)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//        .frame(height: (UIScreen.main.bounds.width - (20 + 15)) / 3)
        .frame(height: ((imageWidth + 10) * 2) + 20)
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: HorizontalAlignment.center) {
                    HStack(alignment: VerticalAlignment.center, spacing: 20) {
                        VStack {
                            if viewModel.isProfileImageUpdated {
                                Image(uiImage: viewModel.uiImage ?? UIImage(named: "empty-avatar")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if (viewModel.viewer?.profilePictureURL == nil) {
                                Image("empty-avatar")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                CBZNetworkImage(imageURL: URL(string: (viewModel.viewer?.profilePictureURL)!)!,
                                                placeholderImage: UIImage(named: "empty-avatar")!)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            }
                        }.id(viewModel.profilePictureUpdated)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let viewer = viewer, let loggedInUser = viewModel.loggedInUser, viewer.uid == loggedInUser.uid {
                                    showProfileImageAction = true
                                }
                            }
                    }
                    .padding()
                    Text(viewModel.viewer?.fullName() ?? "")
                    HStack {
                        Text("My Photos".localizedInApp)
                            .foregroundColor(Color(uiConfig.mainTextColor))
                            .font(.system(size: 16, weight: .heavy))
                        Spacer()
                        CBZPageIndicator(numPages: viewModel.userPhotos.count,
                                         currentPageTintColor: uiConfig.mainThemeForegroundColor,
                                         pageIndicatorTintColor: UIColor(hexString: "#e6e7e9"),
                                         currentPage: $currentPageIndex)
                            .id(viewModel.userPhotosUpdated)
                    }.padding(.horizontal)
                        .padding(.top, 20)
                    userPhotosView
                        .padding(.horizontal, 10)
                    Button(action: {
                        isNavigationActive = true
                        profileSettings = .accountDetails
                    }) {
                        CBZProfileItemView(icon: "account-male-icon", title: "Account Details".localizedInApp, color: UIColor(hexString: "#6979F8"), uiConfig: uiConfig)
                            .padding()
                    }
                    Button(action: {
                        isNavigationActive = true
                        profileSettings = .upgradeAccount
                    }) {
                        CBZProfileItemView(icon: "dating-vip-icon", title: "Upgrade Account".localizedInApp, color: .clear, uiConfig: uiConfig)
                            .padding()
                    }
                    Button(action: {
                        isNavigationActive = true
                        profileSettings = .settings
                    }) {
                        CBZProfileItemView(icon: "settings-menu-item", title: "Settings".localizedInApp, color: UIColor(hexString: "#3F3356"), uiConfig: uiConfig)
                            .padding()
                    }
                    Button(action: {
                        isNavigationActive = true
                        profileSettings = .contactUs
                    }) {
                        CBZProfileItemView(icon: "contact-call-icon", title: "Contact Us".localizedInApp, color: UIColor(hexString: "#64E790"), uiConfig: uiConfig)
                            .padding()
                    }
                    Button(action: {
                        self.store.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout".localizedCore)
                                .foregroundColor(Color(uiConfig.mainTextColor))
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }.padding()
                    }
                    Spacer()
                }
            }
            VStack {
                
            }.sheet(isPresented: $showMyPhotoAddImagePicker, onDismiss: {
                    showMyPhotoAddImagePicker = false
                }, content: {
                    CBZImagePicker(isShown: self.$showMyPhotoAddImagePicker, isShownSheet: self.$showMyPhotoAddImagePicker, sourceType: showMyPhotoAddImageSourceType)  { (image, url) in
                        if let image = image {
                            self.viewModel.didAddImage(image)
                        }
                    }
                })
                .actionSheet(isPresented: $showMyPhotoAddImageAction) {
                    myPhotoAddImageSheet
                }
            VStack {
                
            }.sheet(isPresented: $showImagePicker, onDismiss: {
                    showImagePicker = false
                }, content: {
                    CBZImagePicker(isShown: self.$showImagePicker, isShownSheet: self.$showImagePicker)  { (image, url) in
                        if let image = image {
                            self.viewModel.uiImage = image
                        }
                    }
                })
                .actionSheet(isPresented: $showProfileImageAction) {
                    if viewModel.isProfileImageUpdated {
                        if viewModel.uiImage == nil {
                            return sheet1
                        } else {
                            return sheet2
                        }
                    } else if (viewModel.viewer?.profilePictureURL == nil) {
                        return sheet1
                    } else if let viewer = viewModel.viewer, viewer.hasDefaultAvatar {
                        return sheet1
                    } else {
                        return sheet2
                    }
                }
        }
        .onAppear {
            if let viewer = viewer, let loggedInUser = viewModel.loggedInUser {
                self.viewModel.viewer = viewer
                if let viewerUID = viewer.uid {
                    self.userManager.fetchUser(userID: viewerUID, completion: { (user, error) in
                        guard let user = user else { return }
                        self.viewModel.viewer = user
                    })
                }
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
        .navigate(using: $isNavigationActive, destination: makeDestination)
    }
    
    @ViewBuilder
    private func makeDestination(for isNavigationActive: Bool) -> some View {
        switch profileSettings {
        case .accountDetails:
            CBZDatingEditProfileView(viewModel: viewModel)
        case .upgradeAccount:
            CBZUpgradeAccountView(uiConfig: uiConfig, appConfig: appConfig, viewer: self.viewer)
        case .settings:
            CBZDatingUserSettings(viewModel: viewModel, appConfig: appConfig)
        case .contactUs:
            CBZContactUsView(uiConfig: uiConfig)
        case .none:
            EmptyView()
        }
    }
}

struct CBZProfileItemView: View {
    
    var icon: String
    var title: String
    var color: UIColor
    var uiConfig: CBZUIConfigurationProtocol

    var body: some View {
        HStack {
            Image(icon)
                .renderingMode(color == .clear ? .original : .template)
                .resizable()
                .frame(width: 25, height: 25)
                .foregroundColor(Color(color))
            Text(title)
                .foregroundColor(Color(uiConfig.mainTextColor))
                .font(.system(size: 16))
                .padding(.leading, 15)
            Spacer()
            Image("forward-arrow-black")
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(Color(UIColor(hexString: "#DBDBDE")))
        }
    }
}
