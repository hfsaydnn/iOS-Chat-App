//
//  CBZMessageView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 26/04/21.
//

import SwiftUI
import FirebaseStorage

struct CBZMessageView: View {
    var viewer: ATCUser? = nil
    @ObservedObject var message: CBZChatMessage
    @Binding var isShowVideoPlayer: Bool
    @Binding var isShownSheet: Bool
    @Binding var videoDownloadURL: URL?
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    @State private var isImageClicked = false
    var isLastMessage: Bool
    @Environment(\.colorScheme) var colorScheme

    var background: some View {
        if (message.sender.senderId == viewer?.uid) {
            return Color(uiConfig.mainThemeForegroundColor)
        } else {
            return Color(UIColor.darkModeColor(hexString: "#E0E0E0"))
        }
    }
    
    func replyMessageHeaderTitleText(message: ATChatMessage) -> String {
        let isMessageSendByYou = self.message.sender.senderId == viewer?.uid
        let isReplyMessageSendByYou = message.sender.senderId == viewer?.uid
        return "\(isMessageSendByYou ? "You" : "\(self.message.atcSender.fullName())") replied\((isMessageSendByYou && isReplyMessageSendByYou) ? "" : (isReplyMessageSendByYou ? " to You" : " to \(message.atcSender.fullName())"))"
    }
    
    var body: some View {
        VStack {
            HStack(alignment: VerticalAlignment.bottom) {
                if message.sender.senderId == viewer?.uid {
                    Spacer()
                } else {
                    if let urlString = message.atcSender.profilePictureURL {
                        CBZNetworkImage(imageURL: URL(string: urlString)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 25, height: 25)
                            .padding([.leading, .bottom], 4)
                    }
                }

                if let message = message.inReplyToItem {
                    VStack {
                        HStack {
                            if message.sender.senderId == viewer?.uid {
                                Spacer()
                            }
                            Image("reply-icon")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(uiConfig.grey2))
                                .frame(width: 20, height: 20)
                            Text(replyMessageHeaderTitleText(message: message))
                                .foregroundColor(Color(uiConfig.grey2))
                                .font(uiConfig.regularFont(size: 12))
                            if message.sender.senderId != viewer?.uid {
                                Spacer()
                            }
                        }.offset(y: 15)
                        HStack {
                            if message.sender.senderId == viewer?.uid {
                                Spacer()
                            }
                            Text(CBZMessageView.message(message: message))
                                .padding(8)
                                .foregroundColor(Color(uiConfig.grey2))
                                .background(Color(UIColor.darkModeColor(hexString: "#F5F5F5")))
                                .cornerRadius(12)
                                .offset(y: 15)
                            if message.sender.senderId != viewer?.uid {
                                Spacer()
                            }
                        }
                        chatItemContainerView
                    }
                } else {
                    chatItemContainerView
                }

                if message.sender.senderId != viewer?.uid {
                    Spacer()
                } else {
                    if let urlString = message.atcSender.profilePictureURL {
                        CBZNetworkImage(imageURL: URL(string: urlString)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 25, height: 25)
                            .padding([.trailing, .bottom], 4)
                    }
                }
            }.fullScreenCover(isPresented: $isImageClicked) {
                if let downloadURL = message.downloadURL {
                    ZStack {
                        CBZNetworkImage(imageURL: downloadURL,
                                        placeholderImage: UIImage(named: "gray-back")!)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        VStack {
                            HStack {
                                Spacer()
                                Image("dismissIcon")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .onTapGesture {
                                        isImageClicked = false
                                    }
                            }
                            Spacer()
                        }.padding(.top, 40)
                        .padding(.trailing, 10)
                    }.ignoresSafeArea()
                    .padding(.top, -13)
                }
            }
            if isLastMessage {
                HStack(alignment: VerticalAlignment.bottom) {
                    if message.sender.senderId == viewer?.uid {
                        Spacer()
                        readUsersImage
                            .padding(.trailing, 10)
                    }
                }
            }
        }
    }
    
    var readUsersImage: some View {
        ZStack {
            if let readUserIDs = message.readUserIDs {
                ForEach(0..<readUserIDs.count, id: \.self) { index in
                    if let participantDict = message.participantProfilePictureURLs.filter({ $0["participantId"] as? String == readUserIDs[index] }).first, let urlString = participantDict["profilePictureURL"] as? String {
                        CBZNetworkImage(imageURL: URL(string: urlString)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 15, height: 15)
                            .offset(x: -CGFloat((index * 7)))
                    }
                }
            }
        }
    }
    
    var chatItemContainerView: some View {
        HStack {
            if message.sender.senderId == viewer?.uid {
                Spacer()
            }
            chatItemView
            if message.sender.senderId != viewer?.uid {
                Spacer()
            }
        }
    }
    
    var chatItemView: some View {
        VStack {
            switch message.kind {
            case .photo(let mediaItem):
                if message.downloadURLCompleted {}
                if let downloadURL = message.downloadURL, message.downloadURLCompleted {
                    Button {
                        self.isImageClicked = true
                    } label: {
                        CBZNetworkImage(imageURL: downloadURL,
                                        placeholderImage: UIImage(named: "gray-back")!)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(12)
                    }
                } else {
                    Image("gray-back")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
            case .video(let mediaItem):
                if let downloadURL = mediaItem.thumbnailUrl {
                    Button {
                        if let downloadURL = message.videoDownloadURL {
                            let storage =  Storage.storage()
                            storage.reference(forURL: downloadURL.absoluteString).downloadURL { (url, error) in
                                
                                guard let url = url else {
                                    return
                                }
                                
                                self.videoDownloadURL = url
                                self.isShownSheet = true
                                self.isShowVideoPlayer = true
                            }
                        }
                    } label: {
                        ZStack {
                            CBZNetworkImage(imageURL: downloadURL,
                                            placeholderImage: UIImage(named: "gray-back")!)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 200)
                                .clipped()
                                .cornerRadius(12)
                            Image("play")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                        }.contentShape(Rectangle())
                    }
                } else {
                    Image(uiImage: mediaItem.image ?? mediaItem.placeholderImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
            case .audio(let item):
                CBZChatAudioView(message: message, isFromSender: (message.sender.senderId == viewer?.uid), appConfig: appConfig, uiConfig: uiConfig)
                    .padding(8)
                    .background(background)
                    .cornerRadius(12)
            case .attributedText(let attributedText, let attributedText1):
                AttributedText(colorScheme == .dark ? attributedText1 : attributedText)
                    .padding(8)
                    .foregroundColor(message.sender.senderId == viewer?.uid ? Color.white : Color(uiConfig.mainTextColor))
                    .background(background)
                    .cornerRadius(12)
            default:
                Text(CBZMessageView.message(message: message))
                    .padding(8)
                    .foregroundColor(message.sender.senderId == viewer?.uid ? Color.white : Color(uiConfig.mainTextColor))
                    .background(background)
                    .cornerRadius(12)
            }
        }
    }
    
    static func message(message: ATChatMessage) -> String {
        if let htmlContent = message.htmlContent {
            return htmlContent.string
        } else {
            return message.content
        }
    }
}
