//
//  CBZChatViewAllGroupMembersView.swift
//  ChatApp
//
//  Created by Mayil Kannan on 25/08/21.
//

import SwiftUI

struct CBZChatViewAllGroupMembersView: View {
    var channel: CBZChatChannel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack() {
                LazyVStack {
                    ForEach(channel.participants, id: \.self) { user in
                        CBZChatViewAllGroupMemberView(user: user, appConfig: appConfig, uiConfig: uiConfig)
                    }
                }
                Spacer()
            }.padding()
        }
        .navigationBarTitle("Members", displayMode: .inline)
    }
}

struct CBZChatViewAllGroupMemberView: View {
    var user: ATCUser
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    
    var body: some View {
        HStack(alignment: VerticalAlignment.center) {
            if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
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
            Text(user.fullName())
                .foregroundColor(Color(uiConfig.mainTextColor))
            Spacer()
        }
        .contentShape(Rectangle())
        .frame(height: 50)
    }
}
