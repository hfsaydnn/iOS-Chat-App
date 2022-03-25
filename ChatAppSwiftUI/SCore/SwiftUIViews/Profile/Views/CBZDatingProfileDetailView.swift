//
//  CBZDatingProfileDetailView.swift
//  DatingApp
//
//  Created by Mayil Kannan on 15/10/21.
//

import SwiftUI

struct CBZDatingProfileDetailView: View {
    var profile: CBZDatingProfile?
    var uiConfig: CBZUIConfigurationProtocol
    let appConfig: CBZDatingInAppConfigurationProtocol
    let viewer: CBZDatingProfile?
    @ObservedObject var viewModel: CBZDatingFeedViewModel
    @State var showMaxSwipedAlertMessage: Bool = false
    @State var showUpgradeView: Bool = false
    @Binding var currentProfile: CBZDatingProfile?
    
    @State private var currentPageIndex = 0
    var userPhotos: [[String]] = []
    var distance = "N/A"

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(profile: CBZDatingProfile?, uiConfig: CBZUIConfigurationProtocol, appConfig: CBZDatingInAppConfigurationProtocol, viewer: CBZDatingProfile?, viewModel: CBZDatingFeedViewModel, currentProfile: Binding<CBZDatingProfile?>) {
        self.profile = profile
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        self.viewer = viewer
        self.viewModel = viewModel
        self._currentProfile = currentProfile
        if let myLocation = viewer?.location, let theirLocation = profile?.location {
            distance = myLocation.stringDistance(to: theirLocation)
        }
        userPhotos = fetchUserPhotos(user: profile) ?? []
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
        return photos
    }
    
    var userPhotosView: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(0..<userPhotos.count) { i in
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<userPhotos[i].count) { j in
                        if userPhotos[i].count > j && !userPhotos[i][j].isEmpty {
                            CBZNetworkImage(imageURL: URL(string: userPhotos[i][j])!,
                                            placeholderImage: UIImage(named: "empty-avatar")!,
                                            needUniqueID: true)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 200)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: HorizontalAlignment.center) {
                        if let profilePicture = profile?.profilePictureURL, let profilePictureURL = URL(string: profilePicture) {
                            CBZNetworkImage(imageURL: profilePictureURL,
                                            placeholderImage: UIImage(named: "gray-background")!)
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 450)
                                .clipped()
                        } else {
                            if let photos = profile?.photos, photos.count > 0, let profilePictureURL = URL(string: photos[0]) {
                                CBZNetworkImage(imageURL: profilePictureURL,
                                                placeholderImage: UIImage(named: "gray-background")!)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 450)
                                    .clipped()
                            } else if let defaultAvatarURL = URL(string: ATCUser.defaultAvatarURL) {
                                CBZNetworkImage(imageURL: defaultAvatarURL,
                                                placeholderImage: UIImage(named: "gray-background")!)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 450)
                                    .clipped()
                            }
                        }
                        HStack {
                            Text(profile?.firstName ?? "")
                                .foregroundColor(Color(uiConfig.mainTextColor))
                                .font(uiConfig.boldFont(size: 32.0))
                            Text("\(profile?.age ?? "")")
                                .foregroundColor(Color(uiConfig.mainTextColor))
                                .font(uiConfig.regularFont(size: 28.0))
                            Spacer()
                            VStack {
                                Button {
                                    self.presentationMode.wrappedValue.dismiss()
                                } label: {
                                    HStack {
                                        Image("arrow-down-icon")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(Color(uiConfig.mainThemeForegroundColor))
                                    .clipShape(Circle())
                                }.padding(.trailing, 10)
                                .offset(y: -30)
                                Spacer()
                            }
                        }
                        .frame(height: 50)
                        .padding(.leading, 20)
                        HStack {
                            VStack {
                                HStack {
                                    Image("educate-school-icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .foregroundColor(Color(uiConfig.mainSubtextColor))
                                    Text(profile?.school ?? "")
                                        .foregroundColor(Color(uiConfig.mainSubtextColor))
                                        .font(uiConfig.regularFont(size: 18.0))
                                    Spacer()
                                }
                                HStack {
                                    Image("pinpoint-place-icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .foregroundColor(Color(uiConfig.mainSubtextColor))
                                    
                                    Text(distance)
                                        .foregroundColor(Color(uiConfig.mainSubtextColor))
                                        .font(uiConfig.regularFont(size: 18.0))
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        if let bio = profile?.bio, !bio.isEmpty {
                            Divider()
                                .background(Color(UIColor(hexString: "#ececec").darkModed))
                            HStack {
                                Text(bio)
                                    .foregroundColor(Color(uiConfig.mainSubtextColor))
                                    .font(uiConfig.regularFont(size: 18.0))
                                Spacer()
                            }
                            Divider()
                                .background(Color(UIColor(hexString: "#eaeaea").darkModed))
                        }
                        HStack {
                            Text("Photos")
                                .foregroundColor(Color(uiConfig.mainTextColor))
                                .font(.system(size: 16, weight: .heavy))
                            Spacer()
                            CBZPageIndicator(numPages: userPhotos.count,
                                             currentPageTintColor: uiConfig.mainThemeForegroundColor,
                                             pageIndicatorTintColor: UIColor(hexString: "#e6e7e9"),
                                             currentPage: $currentPageIndex)
                        }.padding(.horizontal)
                            .padding(.top, 20)
                        userPhotosView
                            .padding(.horizontal)
                        Spacer()
                    }
                }
                
                Spacer()
                
                HStack(spacing: 50) {
                    Button(action: {
                        guard CBZSwipeUserManager.shared.isSwipeAvailable() else {
                            showMaxSwipedAlertMessage = true
                            return
                        }

                        self.presentationMode.wrappedValue.dismiss()

                        if self.viewModel.recommendations.count > viewModel.currentIndex {
                            self.currentProfile = self.viewModel.recommendations[viewModel.currentIndex]
                            viewModel.swipeDirection = .left
                            viewModel.isOffsetStart = true
                            withAnimation {
                                viewModel.offset = -UIScreen.main.bounds.width
                            }
                        }
                    }) {
                        VStack {
                            Image("cross-filled-icon")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(UIColor(hexString: "#fd1b61")))
                        }.frame(width: 60, height: 60)
                    }
                    
                    Button(action: {
                        guard CBZSwipeUserManager.shared.isSwipeAvailable() else {
                            showMaxSwipedAlertMessage = true
                            return
                        }

                        self.presentationMode.wrappedValue.dismiss()

                        if self.viewModel.recommendations.count > viewModel.currentIndex {
                            self.currentProfile = self.viewModel.recommendations[viewModel.currentIndex]
                            viewModel.swipeDirection = .up
                            viewModel.isOffsetStart = true
                            withAnimation {
                                viewModel.offset = -UIScreen.main.bounds.height
                            }
                        }
                    }) {
                        VStack {
                            Image("star-filled-icon-1")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color(UIColor(hexString: "#0495e3")))
                        }.frame(width: 60, height: 60)
                    }
                    
                    Button(action: {
                        guard CBZSwipeUserManager.shared.isSwipeAvailable() else {
                            showMaxSwipedAlertMessage = true
                            return
                        }

                        self.presentationMode.wrappedValue.dismiss()

                        if self.viewModel.recommendations.count > viewModel.currentIndex {
                            self.currentProfile = self.viewModel.recommendations[viewModel.currentIndex]
                            viewModel.swipeDirection = .right
                            viewModel.isOffsetStart = true
                            withAnimation {
                                viewModel.offset = UIScreen.main.bounds.width
                            }
                        }
                    }) {
                        VStack {
                            Image("heart-filled-icon")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(Color(UIColor(hexString: "#11e19d")))
                        }.frame(width: 60, height: 60)
                    }
                }.frame(minWidth: 0, maxWidth: .infinity)
                
                VStack { }.alert(isPresented: $showMaxSwipedAlertMessage) { () -> Alert in
                    Alert(
                        title: Text("Pardon the interruption."),
                        message: Text("You’ve swiped 25 cards today. There’s a lot more waiting for you. Ready to see them? Let's upgrade account now. Otherwise, come back here tomorrow."),
                        primaryButton: .cancel(),
                        secondaryButton: .default(Text("Upgrade Now")) {
                            self.showUpgradeView = true
                        }
                    )
                }
            }.sheet(isPresented: $showUpgradeView, content: {
                CBZUpgradeAccountView(uiConfig: uiConfig, appConfig: appConfig, viewer: self.viewer, showCloseOption: true)
            })
        }
    }
}
