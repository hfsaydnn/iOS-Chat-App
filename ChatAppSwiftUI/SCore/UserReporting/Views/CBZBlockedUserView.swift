//
//  CBZBlockedUserView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 30/05/21.
//

import SwiftUI

struct CBZBlockedUserView: View {
    @ObservedObject var viewModel: CBZBlockedUserViewModel
    var blockedUser: ATCUser
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol

    var body: some View {
        VStack {
            HStack(alignment: VerticalAlignment.center) {
                if let profilePictureURL = blockedUser.profilePictureURL, !profilePictureURL.isEmpty, let url = URL(string: profilePictureURL) {
                    CBZNetworkImage(imageURL: url,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                        .padding(.leading, 4)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                        .padding(.leading, 4)
                }
                VStack {
                    Text(blockedUser.fullName())
                        .foregroundColor(Color(uiConfig.mainTextColor))
                    Text(blockedUser.email ?? "")
                        .foregroundColor(Color(uiConfig.mainTextColor))
                }
                Spacer()
                Button(action: {
                    viewModel.unBlockUser(unBlockUser: blockedUser)
                }) {
                    Text("unblock".localizedFeed)
                        .frame(width: 100)
                        .frame(height: 35)
                        .contentShape(Rectangle())
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .padding(20)
        }
        .frame(height: 100)
        .background(
            Color.white
                .cornerRadius(10)
                .shadow(radius: 10)
        )
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
}
