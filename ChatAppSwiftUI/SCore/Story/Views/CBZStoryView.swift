//
//  CBZStoryView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 09/04/21.
//

import SwiftUI

struct CBZStoryView: View {
    
    var gridItemLayout = [GridItem(.flexible())]
    @Binding var storiesUserState: CBZStoriesUserState
    let imageHeight:CGFloat = 58
    @Binding var isStoryContentPresented: Bool
    @Binding var selectedStories: [ATCStory]
    @Binding var showImagePickerOption: Bool
    @Binding var userStoriesIndex: Int
    @ObservedObject var feedViewModel: CBZFeedViewModel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: gridItemLayout, spacing: 5) {
                if storiesUserState.selfStory == false, let user = feedViewModel.loggedInUser {
                    VStack(alignment: HorizontalAlignment.center) {
                        if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                            CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                            placeholderImage: UIImage(named: "empty-avatar")!)
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: imageHeight, height: imageHeight)
                        } else {
                            Image("empty-avatar")
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: imageHeight, height: imageHeight)
                        }
                        Text("Add Story".localizedFeed)
                            .font(uiConfig.regularFont(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .onTapGesture {
                        showImagePickerOption = true
                    }
                }
                ForEach(0..<storiesUserState.users.count, id: \.self) { index in
                    let user = storiesUserState.users[index]
                    VStack(alignment: HorizontalAlignment.center) {
                        VStack {
                            if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                                CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                                placeholderImage: UIImage(named: "empty-avatar")!,
                                                needUniqueID: true)
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                                    .frame(width: imageHeight, height: imageHeight)
                            } else {
                                Image("empty-avatar")
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: imageHeight, height: imageHeight)
                                    .id(UUID())
                            }
                        }
                        .padding(4)
                        .overlay(Circle().stroke(Color(UIColor(hexString: "#4991EC")), lineWidth: 2))
                        Text(user.uid == feedViewModel.loggedInUser?.uid ? "My Story".localizedFeed : user.fullName())
                            .font(uiConfig.regularFont(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .id(UUID())
                    }
                    .onTapGesture {
                        isStoryContentPresented = true
                        userStoriesIndex = index
                        selectedStories = storiesUserState.stories[userStoriesIndex]
                    }
                }
            }.padding(.horizontal, 5)
        }.id(feedViewModel.storyUpdatingTime)
    }
}
