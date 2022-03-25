//
//  CBZChatThreadViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/04/21.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AVKit

class CBZChatThreadViewModel: ObservableObject, SocialFeedsChatFeedUpdateProtocol {
    private let paginationBatchSize = 50
    @Published var messages: [CBZChatMessage] = []

    @Published var chatText: NSAttributedString = NSAttributedString()
    @Published var allTagUsers: [String] = []
    var inReplyToMessage: String?
    @Published var sortedRecipients: [ATCUser] = []
    
    @Published var showingSheet: Bool = false
    @Published var showAction: Bool = false
    @Published var showFriendGroupActionSheet: Bool = false
    @Published var showReportUserActionSheet: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var showVideoPlayer: Bool = false
    @Published var videoDownloadURL: URL?
    @Published var showingAlert: Bool = false
    @Published var showingAlertForBlockUser: Bool = false
    @Published var showingAlertForRenameGroup: Bool = false
    @Published var showAllGroupMembers: Bool = false
    @Published var isOkayPressed: Bool = false {
        didSet {
            showingAlertForRenameGroup = false
            if let groupNameText = groupNameText, isOkayPressed, !groupNameText.isEmpty {
                chatTitleText = groupNameText
                self.renameGroup(channel: channel, name: groupNameText)
            }
        }
    }
    @Published var groupNameText: String? = ""
    @Published var chatTitleText: String = ""
    var channel: CBZChatChannel
    @Published var showRecordView: Bool = false
    @Published var showLoader: Bool = false
    @Published var showTypingIndicator: Bool = false
    @Published var isReplyingItem: Bool = false
    var replyingItemMessage: ATChatMessage?
    var chatSignalListener: ListenerRegistration?
    
    private var isTyping: Bool = false
    private var typingTimer: Timer?
    
    private var user: ATCUser?
    @ObservedObject var conversationsViewModel: CBZConversationsViewModel

    init(channel: CBZChatChannel, user: ATCUser?, conversationsViewModel: CBZConversationsViewModel) {
        self.channel = channel
        self.user = user
        self.conversationsViewModel = conversationsViewModel
    }

    func fetchChat(channel: CBZChatChannel, user: ATCUser?) {
        guard let user = user, let uid = user.uid else { return }

        let storage =  Storage.storage()

        let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))
        reference
            .order(by: "created", descending: true)
            .limit(to: paginationBatchSize)
            .getDocuments(completion: {[weak self] (snapshot, error) in
                guard let `self` = self else { return }
                guard let docs = snapshot?.documents else { return }
                var firstMessages: [CBZChatMessage] = []
                for doc in docs {
                    guard let message = CBZChatMessage(user: user, document: doc) else {
                        return
                    }
                    if let url = message.downloadURL {
                        if let url = message.downloadURL {
                            message.image = UIImage()
                        }
                        firstMessages.append(message)
                        storage.reference(forURL: url.absoluteString).downloadURL { [weak self] (url, error) in
                            guard let `self` = self else {
                                return
                            }
                            guard let url = url else {
                                return
                            }

                            message.objectWillChange.send()
                            message.downloadURL = url
                            message.downloadURLCompleted = true
//                            self.insertNewMessage(message)
                        }
                    } else {
                        firstMessages.append(message)
                    }
                }
                self.insertMessages(firstMessages)
                self.setupMessageListener(channel: channel, user: user)
                if let lastMessage = self.messages.first {
                    self.saveSeenStatusIfNeeded(message: lastMessage)
                }
        })
    }
    
    private func setupMessageListener(channel: CBZChatChannel, user: ATCUser) {
        let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))
        chatSignalListener = reference.addSnapshotListener { [weak self] querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            guard let `self` = self else { return }

            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change, user: user)
            }
            
            if let lastMessage = self.messages.first {
                self.saveSeenStatusIfNeeded(message: lastMessage)
            }
        }
        
        let channelReference = Firestore.firestore().collection("channels").document(channel.id)
        channelReference.addSnapshotListener { [weak self] snapshot, error in
            guard let querySnapshot = snapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            guard let `self` = self else { return }
            guard let data = querySnapshot.data() else { return }
            
            let typingUsers = data["typingUsers"] as? [[String: Any]] ?? []

            if typingUsers.firstIndex(where: { typingUser in ((typingUser["isTyping"] as? Bool ?? false) == true && (typingUser["userID"] as? String ?? "") != user.uid) }) != nil {
                self.showTypingIndicator = true
            } else {
                self.showTypingIndicator = false
            }
        }
    }
    
    fileprivate func saveSeenStatusIfNeeded(message: ATChatMessage) {
        guard let user = user, let uid = user.uid else { return }
        if (message.readUserIDs.filter { $0 == uid }).isEmpty {
            let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))
            reference.document(message.messageId).getDocument(completion: { (snapshot, error) in
                guard let snapshot = snapshot else {
                    return
                }
                let document = snapshot.data()
                var readUserIDs = document?["readUserIDs"] as? [String] ?? []
                readUserIDs.append(uid)
                reference.document(message.messageId).setData(["readUserIDs": readUserIDs], merge: true)
                let channelRef = Firestore.firestore()
                                    .collection("channels")
                                    .document(self.channel.id)
                channelRef.setData(["readUserIDs": readUserIDs], merge: true)
                self.conversationsViewModel.channels.filter({ $0.id == self.channel.id }).first?.readUserIDs.append(uid)
            })
        }
    }
    
    func removeChatListener() {
        if let chatSignalListener = chatSignalListener {
            chatSignalListener.remove()
        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange, user: ATCUser) {
        guard let message = CBZChatMessage(user: user, document: change.document) else {
            return
        }
        switch change.type {
        case .added:
            if let url = message.downloadURL {
                if let url = message.downloadURL {
                    message.image = UIImage()
                }
                self.insertNewMessage(message)
                let storage =  Storage.storage()
                storage.reference(forURL: url.absoluteString).downloadURL { [weak self] (url, error) in
                    guard let `self` = self else {
                        return
                    }
                    guard let url = url else {
                        return
                    }

                    message.objectWillChange.send()
                    message.downloadURL = url
                    message.downloadURLCompleted = true
                    self.insertNewMessage(message)
                }
            } else if message.audioDownloadURL != nil {
                self.insertNewMessage(message)
            } else {
                insertNewMessage(message)
            }
        case .modified:
            insertNewMessage(message)
        default:
            break
        }
    }
    
    private func insertMessages(_ newMessages: [CBZChatMessage]) {
        messages.append(contentsOf: newMessages)
        messages.sort(by: { $0.sentDate > $1.sentDate })
    }
    
    private func insertNewMessage(_ message: CBZChatMessage) {
        if messages.contains(message) {
            self.messages = self.messages.filter { $0 != message }
        }

        messages.append(message)
        messages.sort(by: { $0.sentDate > $1.sentDate })
    }
    
    @objc func updateTypingStatus() {
        setTypingStatus(isTyping: false)
    }
    
    func setTypingStatus(isTyping: Bool) {
        guard let user = user, let uid = user.uid else { return }
        
        if self.isTyping != isTyping {
            self.isTyping = isTyping

            if typingTimer != nil {
                typingTimer?.invalidate()
            }
            if isTyping {
                typingTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(updateTypingStatus), userInfo: nil, repeats: false)
            }
            
            let channelRef = Firestore.firestore().collection("channels").document(self.channel.id)
            channelRef.getDocument { (snapshot, error) in
                if let _ = error {
                    print("No doc found")
                    return
                }
                
                guard let querySnapshot = snapshot else { return }
                guard let data = querySnapshot.data() else { return }
        
                var typingUsers = data["typingUsers"] as? [[String: Any]] ?? []
                let updatingData = ["isTyping": isTyping,
                                    "userID": uid] as [String : Any]
                if let typingUserIndex = typingUsers.firstIndex(where: { typingUser in (typingUser["userID"] as? String ?? "") == uid }) {
                    typingUsers[typingUserIndex] = updatingData
                } else {
                    typingUsers.append(updatingData)
                }
                let typingUsersData: [String : Any] = [
                    "typingUsers": typingUsers
                ]
                channelRef.setData(typingUsersData, merge: true)
            }
        }
    }
    
    func save(_ message: ATChatMessage, _ channel: CBZChatChannel, allTagUsers: [String] = [], user: ATCUser?) {
        guard let user = user, let userID = user.uid else { return }
        let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))
        let messageWithParticipants = channel.addParticipants(userID: userID, message: message)
        reference.addDocument(data: messageWithParticipants.dict) {[weak self] error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            guard let `self` = self else { return }

            self.updateLastMessage(userID: userID, channel: channel, channelID: channel.id, message: message, allTagUsers: allTagUsers, participantProfilePictureURLs: messageWithParticipants.picUrls)
            self.updateChannelParticipationIfNeeded(channel: channel)
            self.sendOutPushNotificationsIfNeeded(message: message, user: user, channel: channel)
        }
    }
    
    private func sendOutPushNotificationsIfNeeded(message: ATChatMessage, user: ATCUser?, channel: CBZChatChannel) {
        var lastMessage = ""
        let senderName = user?.firstName ?? "Someone"
        switch message.kind {
        case let .text(text):
            lastMessage = text
        case let .attributedText(text, text1):
            lastMessage = text.string
        case .photo:
            lastMessage = "\(senderName) sent you a photo."
        case .audio:
            lastMessage = "\(senderName) sent you an audio message."
        case .video:
            lastMessage = "\(senderName) sent you a video message."
        default:
            break
        }

        let notificationSender = ATCPushNotificationSender()
        channel.participants.forEach { (recipient) in
            if let token = recipient.pushToken, recipient.uid != user?.uid {
                notificationSender.sendPushNotification(token: token,
                                                        title: user?.firstName ?? "Instachatty",
                                                        body: lastMessage,
                                                        notificationType: .chatAppNewMessage,
                                                        payload: ["channelId" : channel.id])
            }
        }
    }
    
    func updateChannelParticipationIfNeeded(channel: CBZChatChannel) {
        if channel.participants.count != 2 {
            return
        }
        guard let uid1 = channel.participants.first?.uid, let uid2 = channel.participants[1].uid else { return }
        self.updateChannelParticipationIfNeeded(channel: channel, uID: uid1)
        self.updateChannelParticipationIfNeeded(channel: channel, uID: uid2)
    }
    
    private func updateChannelParticipationIfNeeded(channel: CBZChatChannel, uID: String) {
        let ref1 = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uID).whereField("channel", isEqualTo: channel.id)
        ref1.getDocuments { (querySnapshot, error) in
            if (querySnapshot?.documents.count == 0) {
                let data: [String: Any] = [
                    "user": uID,
                    "channel": channel.id
                ]
                Firestore.firestore().collection("channel_participation").addDocument(data: data, completion: nil)
            }
        }
    }
    
    func sendPhoto(_ image: UIImage, channel: CBZChatChannel, user: ATCUser?) {
        guard let user = user else { return }

        uploadImage(image, to: channel) { [weak self] url in
            guard let `self` = self else {
                return
            }

            guard let url = url else {
                return
            }
            let message = ATChatMessage(user: user, image: image, url: url)
            message.downloadURL = url
            message.readUserIDs = [user.uid ?? ""]
            self.save(message, channel, user: user)
        }
    }
    
    private func uploadImage(_ image: UIImage, to channel: CBZChatChannel, completion: @escaping (URL?) -> Void) {

        guard let scaledImage = image.scaledToSafeUploadSize, let data = scaledImage.jpegData(compressionQuality: 0.4) else {
            completion(nil)
            return
        }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let storage = Storage.storage().reference()
        storage.child(channel.id).child(imageName).putData(data, metadata: metadata) { meta, error in
            if let name = meta?.path, let bucket = meta?.bucket {
                let path = "gs://" + bucket + "/" + name
                completion(URL(string: path))
            } else {
                completion(nil)
            }
        }
    }
    
    func sendMedia(_ videoFileUrl: URL, channel: CBZChatChannel, user: ATCUser?) {
        guard let user = user else { return }

        self.uploadMediaMessage(videoFileUrl, to: channel) { [weak self] url in
            
            guard let `self` = self else {
                return
            }

            guard let url = url else {
                return
            }
            
            let asset = AVURLAsset(url: videoFileUrl, options: nil)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            var videoThumbnail = UIImage()
            do {
                let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
                videoThumbnail = UIImage(cgImage: thumbnailImage)
            } catch let error {
                print(error)
            }
            let videoDuration = asset.duration
            let videoDurationSeconds = CMTimeGetSeconds(videoDuration)

            self.uploadImage(videoThumbnail, to: channel) { [weak self] thumbnailUrl in
                guard let `self` = self else {
                    return
                }

                guard let thumbnailUrl = thumbnailUrl else {
                    return
                }
                
                let storage =  Storage.storage()
                storage.reference(forURL: thumbnailUrl.absoluteString).downloadURL { (thumbnailOriginalUrl, error) in
                    if let videoThumbnailUrl = thumbnailOriginalUrl {
                        let message = ATChatMessage(user: user, videoThumbnailURL: videoThumbnailUrl, videoURL: url, videoDuration: Float(videoDurationSeconds))
                        message.videoDownloadURL = url
                        message.videoThumbnailURL = videoThumbnailUrl
                        message.readUserIDs = [user.uid ?? ""]
                        self.save(message, channel, user: user)
                    }
                }
            }
        }
    }
    
    private func uploadMediaMessage(_ url: URL, to channel: CBZChatChannel, completion: @escaping (URL?) -> Void) {
        
        let hud = CPKProgressHUD.progressHUD(style: .loading(text: "Sending".localizedChat))

        let fileName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let storage = Storage.storage().reference()
        storage.child(channel.id).child(fileName).putFile(from: url, metadata: nil) { (meta, error) in
            hud.dismiss()
            if let name = meta?.path, let bucket = meta?.bucket {
                let path = "gs://" + bucket + "/" + name
                completion(URL(string: path))
            } else {
                completion(nil)
            }
        }
    }
    
    func reportAction(sourceUser: ATCUser?, destUser: ATCUser?, reason: ATCReportingReason) {
        guard let sourceUser = sourceUser else { return }
        guard let destUser = destUser else { return }

        let reportingManager = ATCFirebaseUserReporter()
        reportingManager.report(sourceUser: sourceUser,
                                destUser: destUser,
                                reason: reason) { (success) in
            
        }
    }
    
    func blockUser(sourceUser: ATCUser?, destUser: ATCUser?, completion: @escaping (_ success: Bool) -> Void) {
        guard let sourceUser = sourceUser else { return }
        guard let destUser = destUser else { return }

        let reportingManager = ATCFirebaseUserReporter()
        reportingManager.block(sourceUser: sourceUser,
                               destUser: destUser) { (success) in
            completion(success)
        }
    }
    
    func renameGroup(channel: CBZChatChannel, name: String) {
        let data: [String : Any] = [
            "name": name
        ]
        Firestore.firestore().collection("channels").document(channel.id).setData(data, merge: true)
    }
    
    func leaveGroup(channel: CBZChatChannel, user: ATCUser?) {
        guard let user = user, let uid = user.uid else {
            return
        }
        let ref = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uid).whereField("channel", isEqualTo: channel.id)
        ref.getDocuments { (snapshot, error) in
            if let snapshot = snapshot {
                snapshot.documents.forEach({ (document) in
                    Firestore.firestore().collection("channel_participation").document(document.documentID).delete()
                })
            }
        }
    }
    
    func resetReplyingItem() {
        isReplyingItem = false
        replyingItemMessage = nil
    }
}

protocol SocialFeedsChatFeedUpdateProtocol { }

extension SocialFeedsChatFeedUpdateProtocol {
    
    func updateLastMessage(userID: String, channel: CBZChatChannel, channelID: String, message: ATChatMessage, allTagUsers: [String] = [], participantProfilePictureURLs: [[String: String]]) {
        
        let channelRef = Firestore.firestore().collection("channels").document(channelID)
        var lastMessage = ""
        switch message.kind {
        case let .text(text), let .inReplyToItem((_, text)):
            lastMessage = text
        case let .attributedText(text, text1):
            lastMessage = text.fetchAttributedText(allTagUsers: allTagUsers)
        case .audio(_):
            lastMessage = "Someone sent an audio message.".localizedChat
        case .photo(_):
            lastMessage = "Someone sent a photo.".localizedChat
        case .video(_):
            lastMessage = "Someone sent a video.".localizedChat
        default:
            break
        }
        
        let participantsDict = channel.participants.map({ $0.representation })
        let newData: [String: Any] = [
            "lastMessage": lastMessage,
            "lastThreadMessageId": channelRef.documentID,
            "lastMessageSenderId": userID,
            "readUserIDs": [userID],
            "participantProfilePictureURLs": participantProfilePictureURLs,
            "participants": participantsDict,
            "lastMessageDate": Date()
        ]
        channelRef.setData(newData, merge: true)
        self.updateSocialFeedsChatFeed(userID: userID, channel: channel, lastMessage: lastMessage, channelID: channel.id)
    }
    
    private func updateSocialFeedsChatFeed(userID: String, channel: CBZChatChannel, lastMessage: String, channelID: String) {
        channel.participants.forEach { participant in
            guard let participantID = participant.uid else { return }
            self.updateSocialFeedsChatFeedValues(user: participant, channel: channel, lastMessage: lastMessage, markedAsRead: userID == participantID, channelID: channelID)
        }
    }
    
    private func updateSocialFeedsChatFeedValues(user: ATCUser?, channel: CBZChatChannel, lastMessage: String, markedAsRead: Bool, channelID: String) {
        guard let user = user, let userID = user.uid else { return }
        let otherParticipants = channel.participants.filter({ $0.uid != userID })
        let otherParticipantsDict = otherParticipants.map({ $0.representation })
        let newData: [String: Any] = [
            "id": channel.id,
            "title": title(channel: channel, viewer: user),
            "content": lastMessage,
            "markedAsRead": markedAsRead,
            "createdAt": FieldValue.serverTimestamp(),
            "participants": otherParticipantsDict
        ]
        Firestore.firestore().collection("social_feeds").document(userID).collection("chat_feed").document(channelID)
            .setData(newData, merge: true)
    }
    
    fileprivate func title(channel: CBZChatChannel, viewer: ATCUser?) -> String {
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
}
