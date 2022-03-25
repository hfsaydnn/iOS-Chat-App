//
//  CBZConversationView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/04/21.
//

import SwiftUI

struct CBZConversationView: View {
    var channel: CBZChatChannel
    var viewer: ATCUser? = nil
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @State var showChatThread: Bool = false
    @ObservedObject var conversationViewModel: CBZConversationsViewModel

    var body: some View {
        let unseenByMe = channel.readUserIDs.filter { $0 == viewer?.uid }.isEmpty
        let participants = channel.participants
        let imageURLs = self.imageURLs(participants: participants)
        
        NavigationLink(destination: CBZChatThreadView(viewer: viewer, channel: channel, appConfig: appConfig, uiConfig: uiConfig, conversationsViewModel: conversationViewModel), isActive: $showChatThread) {
        }
        HStack(alignment: VerticalAlignment.center) {
            if imageURLs.count < 2 {
                if let profilePictureURL = imageURLs.first, !profilePictureURL.isEmpty {
                    CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 60, height: 60)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 60, height: 60)
                }
            } else {
                ZStack {
                    if let profilePictureURL = imageURLs.first, !profilePictureURL.isEmpty {
                        CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.leading,.bottom], 15)
                    } else {
                        Image("empty-avatar")
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.leading,.bottom], 15)
                    }
                    
                    if let profilePictureURL = imageURLs[1], !profilePictureURL.isEmpty {
                        CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.trailing,.top], 15)
                    } else {
                        Image("empty-avatar")
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.trailing,.top], 15)
                    }
                }.frame(width: 60, height: 60)
            }
            VStack(alignment: HorizontalAlignment.leading, spacing: 5) {
                HStack {
                    Text(self.title(channel: channel))
                        .font(unseenByMe ? uiConfig.boldFont(size: 17) : uiConfig.semiBoldFont)
                        .foregroundColor(Color(uiConfig.mainTextColor))
                    Spacer()
                }
                HStack {
                    Text(self.subtitle(channel: channel).string)
                        .lineLimit(2)
                        .font(unseenByMe ? uiConfig.boldFont(size: 13) : uiConfig.mediumFont(size: 13))
                        .foregroundColor(Color(unseenByMe ? uiConfig.mainTextColor : uiConfig.mainSubtextColor))
                    Spacer()
                }
            }
        }.contentShape(Rectangle())
        .onTapGesture {
            NotificationCenter.default.post(name: kConversationsScreenHiddenNotificationName, object: nil, userInfo: nil)
            showChatThread = true
        }
        .padding(10)
    }
    
    fileprivate func imageURLs(participants: [ATCUser]) -> [String] {
        var res: [String] = []
        for p in participants {
            if p.uid != viewer?.uid, let profilePictureURL = p.profilePictureURL {
                res.append(profilePictureURL)
            }
        }
        return res.sorted { $0 < $1 }
    }
    
    fileprivate func title(channel: CBZChatChannel) -> String {
        if channel.name.count > 0 {
            return channel.name
        }
        let participants = channel.participants
        var name = ""
        for p in participants {
            if p.uid != viewer?.uid {
                let tmp = (participants.count > 2) ? p.firstWordFromName() : p.fullName()
                if name.count == 0 {
                    name += tmp
                } else {
                    name += ", " + tmp
                }
            }
        }
        return name
    }
    
    fileprivate func subtitle(channel: CBZChatChannel) -> NSMutableAttributedString {
        let lastMessage = channel.lastMessage
        let subtitle = NSMutableAttributedString(string: lastMessage)
        subtitle.append(NSAttributedString(string: " \u{00B7} " + TimeFormatHelper.chatString(for: channel.lastMessageDate)))
        return subtitle
    }
}
