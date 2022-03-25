//
//  CBZChatFriendView.swift
//  ChatApp
//
//  Created by Mayil Kannan on 22/07/21.
//

import SwiftUI

struct CBZChatFriendView: View {
    var friendship: ATCChatFriendship?
    var viewer: ATCUser?
    var user: ATCUser
    @ObservedObject var viewModel: CBZChatFriendsViewModel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    var whiteSmoke: UIColor = UIColor.modedColor(light: "#f5f5f5", dark: "#222222")

    var followerActionText: String {
        guard let friendship = friendship else {
            return "Add"
        }
        switch friendship.type {
        case .inbound:
            return "Accept".localizedChat
        case .outbound:
            return "Cancel".localizedCore
        case .mutual:
            return "Unfriend".localizedCore
        }
    }
    
    var body: some View {
        HStack(alignment: VerticalAlignment.center) {
            if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                placeholderImage: UIImage(named: "empty-avatar")!)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 45, height: 45)
                    .padding(.leading, 4)
            } else {
                Image("empty-avatar")
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 45, height: 45)
                    .padding(.leading, 4)
            }
            Text(user.fullName())
                .foregroundColor(Color(uiConfig.mainTextColor))
                .font(uiConfig.mediumFont(size: 15))
            Spacer()
            if !followerActionText.isEmpty {
                Button(action: {
                    guard let friendship = friendship else {
                        self.viewModel.addFriendRequest(fromUser: viewer, toUser: user)
                        return
                    }
                    switch friendship.type {
                    case .inbound:
                        // Accept friendship
                        self.viewModel.acceptFriendRequest(fromUser: friendship.otherUser,
                                                           toUser: friendship.currentUser)
                        break
                    case .outbound:
                        // Cancel friend request
                        self.viewModel.cancelFriendRequest(fromUser: friendship.currentUser,
                                                           toUser: friendship.otherUser)
                    case .mutual:
                        // Cancel friend request
                        self.viewModel.unFriendRequest(fromUser: friendship.currentUser,
                                                           toUser: friendship.otherUser)
                    }
                    viewModel.followTextUpdatingTime = Date()
                }) {
                    Text(followerActionText)
                        .font(uiConfig.regularFont(size: 15))
                        .frame(width: 82)
                        .frame(height: 26)
                        .contentShape(Rectangle())
                        .foregroundColor(Color(uiConfig.mainTextColor))
                        .background(Color(whiteSmoke))
                        .cornerRadius(12)
                        .id(viewModel.followTextUpdatingTime)
                }.padding(.trailing, 20)
            }
        }
        .frame(height: 50)
    }
}
