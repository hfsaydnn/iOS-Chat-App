//
//  CBZNotificationView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/05/21.
//

import SwiftUI

struct CBZNotificationView: View {
    var notification: CBZFeedPostNotification
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    
    var body: some View {
        VStack {
            HStack(alignment: VerticalAlignment.center) {
                if let profilePictureURL = notification.notificationAuthorProfileImage, !profilePictureURL.isEmpty {
                    CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .padding(.leading, 4)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                        .padding(.leading, 4)
                }
                VStack {
                    let notificationAuthorName = notification.notificationAuthorUsername
                    let reactionText = " reacted to your post.".localizedFeed
                    let commentedText = " commented on your post.".localizedFeed
                    
                    let message = notification.reacted ? notificationAuthorName + reactionText : notificationAuthorName + commentedText
                    HStack {
                        Text(message)
                            .lineLimit(nil)
                            .font(uiConfig.regularSmallFont)
                            .foregroundColor(Color(uiConfig.mainTextColor))
                        Spacer()
                    }
                    HStack {
                        Text(TimeFormatHelper.timeAgoString(date: notification.createdAt ?? Date()))
                            .font(uiConfig.regularFont(size: 12))
                            .foregroundColor(Color(uiConfig.mainTextColor))
                            .padding(.top, 8)
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding()
            Divider()
        }
    }
}
