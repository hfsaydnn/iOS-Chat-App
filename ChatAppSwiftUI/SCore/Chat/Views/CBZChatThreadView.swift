//
//  CBZChatThreadView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/04/21.
//

import SwiftUI
import AVKit

struct CBZChatThreadView: View {
    var viewer: ATCUser? = nil
    @StateObject private var viewModel: CBZChatThreadViewModel
    var channel: CBZChatChannel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    var hideNavigation: Bool = true
    var blockUserText = "Are you sure you want to block this user? You won't see their messages again.".localizedChat
    var leaveGroupText = "Are you sure you want to leave this group?".localizedChat
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var conversationsViewModel: CBZConversationsViewModel

    init(viewer: ATCUser? = nil, channel: CBZChatChannel, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol, conversationsViewModel: CBZConversationsViewModel? = nil) {
        self.viewer = viewer
        self.channel = channel
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        let finalConversationsViewModel = conversationsViewModel ?? CBZConversationsViewModel(user: viewer)
        self.conversationsViewModel = finalConversationsViewModel
        _viewModel = StateObject(wrappedValue: CBZChatThreadViewModel(channel: channel, user: viewer, conversationsViewModel: finalConversationsViewModel))
    }
    
    var sheet: ActionSheet {
        ActionSheet(
            title: Text("Photo Upload".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showImagePicker = true
                    self.viewModel.showingSheet = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showImagePicker = true
                    self.viewModel.showingSheet = true
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.viewModel.showAction = false
                })
            ])
    }
    
    var friendActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Actions".localizedCore),
            buttons: [
                .default(Text("Block User".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showingAlert = true
                    self.viewModel.showingAlertForBlockUser = true
                }),
                .default(Text("Report User".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showReportUserActionSheet = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.viewModel.showAction = true
                    }
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                })
            ])
    }
    
    var reportUserActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Why are you reporting this account?".localizedChat),
            buttons: [
                .default(Text("Spam".localizedCore), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .spam)
                }),
                .default(Text("Sensitive photos".localizedChat), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .sensitiveImages)
                }),
                .default(Text("Abusive content".localizedChat), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .abusive)
                }),
                .default(Text("Harmful information".localizedChat), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .harmful)
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.viewModel.showReportUserActionSheet = false
                })
            ])
    }
    
    func reportAction(reason: ATCReportingReason) {
        self.viewModel.reportAction(sourceUser: viewer, destUser: self.otherUser(), reason: reason)
        self.presentationMode.wrappedValue.dismiss()
    }
    
    var groupActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Group Settings".localizedChat),
            buttons: [
                .default(Text("View Group Members".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showAllGroupMembers = true
                }),
                .default(Text("Rename Group".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showingAlertForRenameGroup = true
                }),
                .destructive(Text("Leave Group".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showingAlert = true
                    self.viewModel.showingAlertForBlockUser = false
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                })
            ])
    }
    
    fileprivate func otherUser() -> ATCUser? {
        for recipient in channel.participants {
            if recipient.uid != viewer?.uid {
                return recipient
            }
        }
        return nil
    }
    
    var messageView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(viewModel.messages, id: \.id) { message in
                    ZStack {
                        CBZMessageView(viewer: viewer, message: message, isShowVideoPlayer: $viewModel.showVideoPlayer, isShownSheet: $viewModel.showingSheet, videoDownloadURL: $viewModel.videoDownloadURL, appConfig: appConfig, uiConfig: uiConfig, isLastMessage: message.id == viewModel.messages.first?.id)
                            .modifier(CBZMessageTextLongTapGesture(message: message, longTapHandler: {
                                viewModel.isReplyingItem = true
                                viewModel.replyingItemMessage = message
                            }))
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                    }
                }
            }
        }.scaleEffect(x: 1, y: -1, anchor: .center)
        .padding(.top, 8)
    }
    
    var mentionsView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.sortedRecipients, id: \.self) { user in
                    HStack {
                        if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                            CBZNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                            placeholderImage: UIImage(named: "empty-avatar")!)
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 45, height: 45)
                        } else {
                            Image("empty-avatar")
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 45, height: 45)
                        }
                        VStack {
                            Text(user.fullName())
                                .foregroundColor(Color(uiConfig.mainTextColor))
                        }
                        Spacer()
                    }.frame(height: 55)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.leading)
                    .scaleEffect(x: 1, y: -1, anchor: .center)
                    .onTapGesture {
                        didSelectMentionsUser(member: user)
                    }
                }
            }
        }
        .scaleEffect(x: 1, y: -1, anchor: .center)
        .frame(height: CGFloat(viewModel.sortedRecipients.count * 55))
    }
    
    func didSelectMentionsUser(member: ATCUser) {
        let colorGray0: UIColor = UIColor.darkModeColor(hexString: "#000000")

        if var firstName = member.firstName, var lastName = member.lastName {
            firstName = firstName.trimmingCharacters(in: .whitespaces)
            lastName = lastName.trimmingCharacters(in: .whitespaces)
            let attributedString = self.viewModel.chatText.fetchAttributedText(allTagUsers: self.viewModel.allTagUsers)
            var findText = attributedString.components(separatedBy: "@")
            findText.removeLast()
            findText.append("<font color='\(kMentionsConfig.mentionsColorCode)'>\(firstName)</font>")
            if !lastName.isEmpty {
                findText.append(" <font color='\(kMentionsConfig.mentionsColorCode)'>\(lastName)</font>")
            }
            var myAttributedText = (findText.joined(separator: "@"))
            myAttributedText = myAttributedText.replacingOccurrences(of: "@<font color='\(kMentionsConfig.mentionsColorCode)'>\(firstName)</font>", with: "<font color='\(kMentionsConfig.mentionsColorCode)'>\(firstName)</font>")
            if !lastName.isEmpty {
                myAttributedText = myAttributedText.replacingOccurrences(of: "@ <font color='\(kMentionsConfig.mentionsColorCode)'>\(lastName)</font>", with: " <font color='\(kMentionsConfig.mentionsColorCode)'>\(lastName)</font>")
            }
            self.viewModel.chatText = (myAttributedText + " ")
                .htmlToAttributedString(textColor: colorGray0)
            
            self.viewModel.allTagUsers.append(firstName)
            self.viewModel.allTagUsers.append(lastName)
        }
        
        self.viewModel.sortedRecipients = []
    }
    
    var body: some View {
        VStack {
            NavigationLink(destination: CBZChatViewAllGroupMembersView(channel: channel, appConfig: appConfig, uiConfig: uiConfig), isActive: $viewModel.showAllGroupMembers) { EmptyView() }
            messageView
            mentionsView
            if self.viewModel.showTypingIndicator {
                HStack {
                    CBZTypingIndicatorView()
                        .frame(width: 80, height: 50)
                    Spacer()
                }
            }
            if viewModel.isReplyingItem {
                replyingItemView
            }
            HStack {
                Image("camera-filled-icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                    .frame(width: 20, height: 20)
                    .padding(.leading, 10)
                    .onTapGesture {
                        self.viewModel.showAction = true
                        self.viewModel.showFriendGroupActionSheet = false
                        self.viewModel.showReportUserActionSheet = false
                    }
                HStack {
                    Image("icons8-microphone-24")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                        .frame(width: 20, height: 20)
                        .padding(.leading, 8)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            self.viewModel.showRecordView = true
                        }
                    let binding = Binding<NSAttributedString>(get: {
                        self.viewModel.chatText
                    }, set: {
                        self.viewModel.chatText = $0
                        self.viewModel.setTypingStatus(isTyping: !(self.viewModel.chatText.length == .zero))
                        self.viewModel.showRecordView = false
                    })
                    CBZMentionsTextView(text: binding, placeholder: "Start typing...".localizedCore, allTagUsers: self.$viewModel.allTagUsers, recipients: self.channel.participants, sortedRecipients: self.$viewModel.sortedRecipients)
                        .background(Color.clear)
                        .padding(.leading, 2)
                        .padding(.trailing, 10)
                    Image("send")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                        .frame(width: 20, height: 20)
                        .padding()
                        .onTapGesture {
                            self.handleSendMessageButton()
                        }
                }
                .frame(height: 35)
                .background(Color(uiConfig.grey1))
                .cornerRadius(35/2)
                .padding(10)
            }
            if viewModel.showRecordView {
                CBZChatAudioRecordView(user: self.viewer,
                                       channel: self.channel,
                                       showRecordView: $viewModel.showRecordView,
                                       showLoader: $viewModel.showLoader,
                                       chatThreadViewModel: viewModel)
                    .frame(height: 300)
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
        .sheet(isPresented: $viewModel.showingSheet, onDismiss: {
            if viewModel.showImagePicker {
                viewModel.showImagePicker = false
            } else if viewModel.showVideoPlayer {
                viewModel.showVideoPlayer = false
            }
        }, content: {
            if viewModel.showImagePicker {
                CBZImagePicker(isShown: self.$viewModel.showImagePicker, isShownSheet: self.$viewModel.showingSheet, allMedia: true) { (image, url) in
                    viewModel.resetReplyingItem()
                    if let image = image {
                        viewModel.sendPhoto(image, channel: channel, user: viewer)
                    } else if let url = url {
                        viewModel.sendMedia(url, channel: channel, user: viewer)
                    }
                }
            } else if viewModel.showVideoPlayer {
                if let downloadURL = viewModel.videoDownloadURL {
                    let player = AVPlayer(url: downloadURL)
                    VideoPlayer(player: player)
                        .onAppear() {
                            player.play()
                        }
                }
            }
        })
        .alert(isPresented:$viewModel.showingAlert) {
            if viewModel.showingAlertForBlockUser {
                return Alert(
                    title: Text("Are you sure?".localizedChat),
                    message: Text(blockUserText),
                    primaryButton: .default(Text("Yes".localizedCore)) {
                        self.viewModel.blockUser(sourceUser: viewer, destUser: self.otherUser()) { (success) in
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("\("Leave".localizedChat) \(viewModel.chatTitleText)"),
                    message: Text(leaveGroupText),
                    primaryButton: .default(Text("Yes".localizedCore)) {
                        self.viewModel.leaveGroup(channel: channel, user: viewer)
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .textFieldAlert(isPresented: $viewModel.showingAlertForRenameGroup) { () -> TextFieldAlert in
            TextFieldAlert(title: "Change Name".localizedChat, message: "", text: self.$viewModel.groupNameText, isOkayPressed: $viewModel.isOkayPressed)
        }
        .onAppear {
            self.viewModel.chatTitleText = self.title(channel: channel)
            self.viewModel.messages.removeAll()
            self.viewModel.fetchChat(channel: channel, user: viewer)
        }
        .onDisappear {
            self.viewModel.removeChatListener()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(self.viewModel.chatTitleText, displayMode: .inline)
        .navigationBarItems(leading:
                                Button(action: {
                                    NotificationCenter.default.post(name: kConversationsScreenVisibleNotificationName, object: nil, userInfo: nil)
                                    self.presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image("arrow-back-icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                                },
                            trailing:
                                HStack {
                                    Button(action: {
                                        self.viewModel.showAction = true
                                        self.viewModel.showFriendGroupActionSheet = true
                                    }) {
                                        Image("settings-icon")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(Color(uiConfig.mainThemeForegroundColor))
                                    }
                                })
        .actionSheet(isPresented: $viewModel.showAction) {
            if viewModel.showFriendGroupActionSheet {
                if self.channel.participants.count > 2 || !self.channel.groupCreatorID.isEmpty {
                    return groupActionSheet
                } else {
                    return friendActionSheet
                }
            } else if viewModel.showReportUserActionSheet {
                return reportUserActionSheet
            } else {
                return sheet
            }
        }
    }
    
    var replyingItemView: some View {
        VStack {
            if let replyingItemMessage = viewModel.replyingItemMessage {
                Divider()
                HStack {
                    VStack {
                        HStack {
                            Text("Replying to")
                                .font(uiConfig.regularFont(size: 13))
                            Text(replyingItemMessage.atcSender.fullName())
                                .font(uiConfig.boldFont(size: 13))
                            Spacer()
                        }.padding(.top, 5)
                        HStack {
                            Text(CBZMessageView.message(message: replyingItemMessage))
                                .foregroundColor(Color(uiConfig.grey2))
                                .font(uiConfig.regularFont(size: 13))
                            Spacer()
                        }
                        Spacer()
                    }.padding(.leading, 10)
                    Spacer()
                    VStack {
                        Image("close-x-icon")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(uiConfig.grey2))
                            .padding(.trailing, 10)
                            .onTapGesture {
                                viewModel.resetReplyingItem()
                            }
                        Spacer()
                    }
                }.frame(height: 50)
            }
        }
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
    
    func handleSendMessageButton() {
        if viewModel.chatText.length == .zero { return }
        guard let user = viewer else { return }
        let attributedString = viewModel.chatText
        let message = ATChatMessage(messageId: UUID().uuidString,
                                    messageKind: MessageKind.attributedText(lightModedString: attributedString, darkModedString: attributedString),
                                    createdAt: Date(),
                                    atcSender: user,
                                    recipient: user,
                                    readUserIDs: [user.uid ?? ""],
                                    seenByRecipient: false,
                                    allTagUsers: self.viewModel.allTagUsers,
                                    inReplyToMessage: self.viewModel.inReplyToMessage,
                                    inReplyToItem: self.viewModel.replyingItemMessage)
        viewModel.save(message, channel, user: user)
        viewModel.chatText = NSAttributedString(string: "")
        viewModel.setTypingStatus(isTyping: false)
        viewModel.resetReplyingItem()
    }
}

struct CBZTypingIndicatorView: UIViewRepresentable {

    func makeUIView(context: Context) -> TypingBubble {
        TypingBubble()
    }

    func updateUIView(_ uiView: TypingBubble, context: Context) {
        uiView.startAnimating()
    }
}

struct CBZMessageTextLongTapGesture: ViewModifier {
    
    var message: CBZChatMessage
    var longTapHandler: (() -> Void)?
    
    func body(content: Content) -> some View {
        switch message.kind {
        case .text(_):
            content
                .onTapGesture { }
                .onLongPressGesture {
                    longTapHandler?()
                }
        case .attributedText(_):
            content
                .onTapGesture { }
                .onLongPressGesture {
                    longTapHandler?()
                }
        default:
            content
        }
    }
}

struct CBZMentionsTextView: UIViewRepresentable {
    
    @Binding var text: NSAttributedString
    var placeholder: String
    @Binding var allTagUsers: [String]
    var recipients: [ATCUser]
    @Binding var sortedRecipients: [ATCUser]
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 14)
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.text = placeholder
        textView.textColor = .lightGray
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($text, placeholder, $allTagUsers, recipients, $sortedRecipients)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<NSAttributedString>
        var placeholder: String
        var allTagUsers: Binding<[String]>
        var recipients: [ATCUser]
        var sortedRecipients: Binding<[ATCUser]>
        let colorGray0: UIColor = UIColor.darkModeColor(hexString: "#000000")
        
        init(_ text: Binding<NSAttributedString>, _ placeholder: String, _ allTagUsers: Binding<[String]>, _ recipients: [ATCUser], _ sortedRecipients: Binding<[ATCUser]> ) {
            self.text = text
            self.placeholder = placeholder
            self.allTagUsers = allTagUsers
            self.recipients = recipients
            self.sortedRecipients = sortedRecipients
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == UIColor.lightGray {
                textView.attributedText = nil
                textView.textColor = .black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.attributedText.length == 0 {
                textView.attributedText = NSAttributedString(string: placeholder)
                textView.textColor = .lightGray
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            let textViewPreviousCursor = textView.selectedRange
            
            let attributedString = textView.attributedText.fetchAttributedText(allTagUsers: self.allTagUsers.wrappedValue)
            textView.attributedText = attributedString.htmlToAttributedString(textColor: colorGray0)
            
            textView.selectedRange = textViewPreviousCursor
            
            if textView.text == "@" {
                sortedRecipients.wrappedValue = recipients
            } else {
                let findText1 = textView.text.components(separatedBy: "@")
                
                if findText1.count > 1 {
                    let checkFindText1 = findText1.filter { $0 != findText1.last }
                    let checkFindText2 = checkFindText1.last
                    var checkFindText2Range = checkFindText2?.last?.isWhitespace ?? false
                    if !checkFindText2Range {
                        let lastCharacter: String.Element = checkFindText2?.last ?? Character("@")
                        checkFindText2Range = "\(lastCharacter)".containsEmoji
                    }
                    
                    if checkFindText2Range {
                        let findText = findText1.last
                        let range = findText!.rangeOfCharacter(from: .whitespaces)
                        
                        if !findText!.isEmpty && range == nil {
                            sortedRecipients.wrappedValue = recipients.filter({ (member) -> Bool in
                                if let name = member.firstName {
                                    if name.lowercased().contains(findText!.lowercased()) {
                                        return true
                                    }
                                }
                                if let name = member.lastName {
                                    if name.lowercased().contains(findText!.lowercased()) {
                                        return true
                                    }
                                }
                                return false
                            })
                        } else if findText!.isEmpty && range == nil {
                            sortedRecipients.wrappedValue = recipients
                        }
                    } else if checkFindText2!.isEmpty {
                        let findText = findText1.last
                        let range = findText!.rangeOfCharacter(from: .whitespaces)
                        
                        if !findText!.isEmpty && range == nil {
                            sortedRecipients.wrappedValue = recipients.filter({ (member) -> Bool in
                                if let name = member.firstName {
                                    if name.lowercased().contains(findText!.lowercased()) {
                                        return true
                                    }
                                }
                                if let name = member.lastName {
                                    if name.lowercased().contains(findText!.lowercased()) {
                                        return true
                                    }
                                }
                                return false
                            })
                        } else if findText!.isEmpty && range == nil {
                            sortedRecipients.wrappedValue = recipients
                        }
                    }
                    else{
                        sortedRecipients.wrappedValue = []
                    }
                } else {
                    sortedRecipients.wrappedValue = []
                }
            }
                    
            self.text.wrappedValue = textView.attributedText
        }
    }
}
