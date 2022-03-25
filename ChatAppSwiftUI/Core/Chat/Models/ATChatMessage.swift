//
//  ATChatMessage.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/20/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import Firebase
import FirebaseFirestore

public enum ATCMediaType {
    case video
    case audio
    
    var rawValue: String {
        switch self {
        case .video: return "video"
        case .audio: return "audio"
        }
    }
}

class ATCMediaItem: MediaItem {
    var duration: Float = 0.0
    var thumbnailUrl: URL? = nil
    var url: URL? = nil
    var image: UIImage? = nil
    var placeholderImage: UIImage
    var size: CGSize
    init(url: URL?, image: UIImage? = nil) {
        self.url = url
        self.image = image
        self.placeholderImage = UIImage.localImage("camera-icon")
        self.size = CGSize(width: 500, height: 500)
    }
}

class ATCAudioVideoItem: MediaItem {
    var thumbnailUrl: URL? = nil
    var url: URL? = nil
    var image: UIImage? = nil
    var placeholderImage: UIImage
    var size: CGSize
    var duration: Float
    var mediaType: ATCMediaType
    init(mediaType: ATCMediaType, url: URL?, image: UIImage? = nil, thumbnailUrl: URL? = nil, duration: Float) {
        self.mediaType = mediaType
        self.url = url
        self.image = image
        self.placeholderImage = UIImage.localImage("camera-icon")
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        switch mediaType {
        case .video:
            let screenWidth = UIScreen.main.bounds.width * 50 / 100
            self.size = CGSize(width: screenWidth, height: screenWidth)
        case .audio:
            self.size = CGSize(width: 150, height: 45)
        default:
            self.size = CGSize(width: 500, height: 500)
        }
    }
}

class ATChatMessage: ATCGenericBaseModel, MessageType {
    var id: String?

    var sentDate: Date

    var kind: MessageKind

    lazy var sender: SenderType = Sender(senderId: atcSender.uid ?? "No Id", displayName: atcSender.uid ?? "No Name")

    var atcSender: ATCUser
    var recipient: ATCUser
    var readUserIDs: [String]
    var seenByRecipient: Bool

    var messageId: String {
        return id ?? UUID().uuidString
    }

    var image: UIImage? = nil {
        didSet {
            self.kind = .photo(ATCMediaItem(url: downloadURL, image: self.image))
        }
    }
    var downloadURL: URL? = nil
    var audioDownloadURL: URL? = nil
    var audioDuration: Float? = 0.0

    var videoThumbnailURL: URL? = nil
    var videoDownloadURL: URL? = nil
    var videoDuration: Float? = 0.0

    var content: String = ""
    var htmlContent: NSAttributedString? = nil

    var allTagUsers: [String] = []
    var inReplyToMessage: String?
    var inReplyToItem: ATChatMessage?
    
    var participantProfilePictureURLs: [[String: Any]] = []

    init(messageId: String, messageKind: MessageKind, createdAt: Date, atcSender: ATCUser, recipient: ATCUser, readUserIDs: [String], seenByRecipient: Bool, allTagUsers: [String] = [], inReplyToMessage: String? = nil, inReplyToItem: ATChatMessage? = nil) {
        self.id = messageId
        self.kind = messageKind
        self.sentDate = createdAt
        self.atcSender = atcSender
        self.recipient = recipient
        self.seenByRecipient = seenByRecipient
        self.readUserIDs = readUserIDs
        self.allTagUsers = allTagUsers
        self.inReplyToMessage = inReplyToMessage
        switch messageKind {
        case .text(let text):
            self.content = text
        case .attributedText(let text, let text1):
            self.htmlContent = text
        case let .inReplyToItem((inReplyToMessage, text)):
            self.content = text
            self.inReplyToMessage = inReplyToMessage
        default:
            self.content = ""
            self.htmlContent = nil
        }
        self.inReplyToItem = inReplyToItem
    }

    init(user: ATCUser, image: UIImage, url: URL) {
        self.image = image
        content = ""
        self.htmlContent = nil
        sentDate = Date()
        id = nil
        let mediaItem = ATCMediaItem(url: url, image: nil)
        self.kind = MessageKind.photo(mediaItem)
        self.atcSender = user
        self.recipient = user
        self.readUserIDs = []
        self.seenByRecipient = true
    }
    
    init(user: ATCUser, audioURL: URL, audioDuration: Float) {
        content = ""
        self.htmlContent = nil
        sentDate = Date()
        id = nil
        let audioItem = ATCAudioVideoItem(mediaType: .audio, url: audioURL, duration: audioDuration)
        self.kind = MessageKind.audio(audioItem)
        self.atcSender = user
        self.recipient = user
        self.readUserIDs = []
        self.seenByRecipient = true
        self.audioDuration = audioDuration
    }

    init(user: ATCUser, videoThumbnailURL: URL, videoURL: URL, videoDuration: Float) {
        content = ""
        self.htmlContent = nil
        sentDate = Date()
        id = nil
        let videoItem = ATCAudioVideoItem(mediaType: .video, url: videoURL, thumbnailUrl: videoThumbnailURL, duration: videoDuration)
        self.kind = MessageKind.video(videoItem)
        self.atcSender = user
        self.recipient = user
        self.readUserIDs = []
        self.seenByRecipient = true
        self.videoDuration = videoDuration
    }
    
    convenience init?(user: ATCUser, document: QueryDocumentSnapshot) {
        let data = document.data()
        self.init(user: user, data: data, document: document)
    }
    
    init?(user: ATCUser, data: [String: Any], document: QueryDocumentSnapshot?) {
        guard let sentDate = data["created"] as? Timestamp else {
            return nil
        }
        guard let senderID = data["senderID"] as? String else {
            return nil
        }
        guard let senderFirstName = data["senderFirstName"] as? String else {
            return nil
        }
        guard let senderLastName = data["senderLastName"] as? String else {
            return nil
        }
        guard let senderProfilePictureURL = data["senderProfilePictureURL"] as? String else {
            return nil
        }
        guard let recipientID = data["recipientID"] as? String else {
            return nil
        }
        guard let recipientFirstName = data["recipientFirstName"] as? String else {
            return nil
        }
        guard let recipientLastName = data["recipientLastName"] as? String else {
            return nil
        }
        guard let recipientProfilePictureURL = data["recipientProfilePictureURL"] as? String else {
            return nil
        }

        id = document?.documentID

        self.sentDate = sentDate.dateValue()
        self.atcSender = ATCUser(uid: senderID, firstName: senderFirstName, lastName: senderLastName, avatarURL: senderProfilePictureURL)
        self.recipient = ATCUser(uid: recipientID, firstName: recipientFirstName, lastName: recipientLastName, avatarURL: recipientProfilePictureURL)

        if let content = data["content"] as? String {
            self.content = content
            let textColor = self.atcSender.uid == user.uid ? UIColor.white : UIColor.black
            self.htmlContent = content.htmlToAttributedString(textColor: textColor)
            downloadURL = nil
            if let inReplyToMessage = data["inReplyToMessage"] as? String {
                self.inReplyToMessage = inReplyToMessage
                self.kind = MessageKind.inReplyToItem((inReplyToMessage, content))
            } else {
                let lightModedColor = self.atcSender.uid == user.uid ? UIColor.white : UIColor(hexString: "#151723")
                let darkModedColor = self.atcSender.uid == user.uid ? UIColor.white : UIColor(hexString: "#ffffff")
                self.kind = MessageKind.attributedText(lightModedString: content.htmlToAttributedString(textColor: lightModedColor), darkModedString: content.htmlToAttributedString(textColor: darkModedColor))
            }
        } else if let urlDatas = data["url"] as? [String: Any] {
            let mime = urlDatas["mime"] as? String ?? ""
            let urlString = urlDatas["url"] as? String ?? ""
            let url = URL(string: urlString)
            if mime == "image/jpeg" {
                downloadURL = url
                self.content = ""
                self.htmlContent = nil
                let mediaItem = ATCMediaItem(url: url, image: nil)
                self.kind = MessageKind.photo(mediaItem)
            } else if mime == "audio/mp3" {
                audioDownloadURL = url
                self.content = ""
                self.htmlContent = nil
                audioDuration = urlDatas["audioduration"] as? Float
                let audioItem = ATCAudioVideoItem(mediaType: .audio, url: url, duration: audioDuration ?? 0.0)
                self.kind = MessageKind.audio(audioItem)
            } else if mime == "video/mp4" {
                videoDownloadURL = url
                self.content = ""
                self.htmlContent = nil
                videoDuration = urlDatas["videoduration"] as? Float
                if let thumbnailUrlString = urlDatas["videothumbnailurl"] as? String, let thumbnailUrl = URL(string: thumbnailUrlString) {
                    videoThumbnailURL = thumbnailUrl
                }
                let videoItem = ATCAudioVideoItem(mediaType: .video,
                                                  url: url,
                                                  thumbnailUrl: videoThumbnailURL,
                                                  duration: videoDuration ?? 0.0)
                self.kind = MessageKind.video(videoItem)
            } else {
                return nil
            }
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            self.content = ""
            self.htmlContent = nil
            let mediaItem = ATCMediaItem(url: url, image: nil)
            self.kind = MessageKind.photo(mediaItem)
        } else if let urlString = data["audiourl"] as? String, let url = URL(string: urlString) {
            audioDownloadURL = url
            self.content = ""
            self.htmlContent = nil
            audioDuration = data["audioduration"] as? Float
            let audioItem = ATCAudioVideoItem(mediaType: .audio, url: url, duration: audioDuration ?? 0.0)
            self.kind = MessageKind.audio(audioItem)
        }  else if let urlString = data["videourl"] as? String, let url = URL(string: urlString) {
            videoDownloadURL = url
            self.content = ""
            self.htmlContent = nil
            videoDuration = data["videoduration"] as? Float
            if let thumbnailUrlString = data["videothumbnailurl"] as? String, let thumbnailUrl = URL(string: thumbnailUrlString) {
                videoThumbnailURL = thumbnailUrl
            }
            let videoItem = ATCAudioVideoItem(mediaType: .video,
                                              url: url,
                                              thumbnailUrl: videoThumbnailURL,
                                              duration: videoDuration ?? 0.0)
            self.kind = MessageKind.video(videoItem)
        } else {
            return nil
        }
        self.seenByRecipient = true
        var messageSeeners: [String] = []
        if let readUserIDs = data["readUserIDs"] as? [String] {
            messageSeeners = readUserIDs
        }
        self.readUserIDs = messageSeeners
        if let inReplyToItem = data["inReplyToItem"] as? [String: Any] {
            self.inReplyToItem = ATChatMessage(user: user, data: inReplyToItem, document: nil)
        }
        if let participantProfilePictureURLs = data["participantProfilePictureURLs"] as? [[String: Any]] {
            self.participantProfilePictureURLs = participantProfilePictureURLs
        }
    }

    required init(jsonDict: [String: Any]) {
        fatalError()
    }

    var description: String {
        return self.messageText
    }

    var messageText: String {
        switch kind {
        case .text(let text):
            return text
        case let .inReplyToItem((_, text)):
             return text
        default:
            return ""
        }
    }
    
    var channelId: String {
        let id1 = (recipient.uid ?? "")
        let id2 = (atcSender.uid ?? "")
        return id1 < id2 ? id1 + id2 : id2 + id1
    }
}

extension ATChatMessage: DatabaseRepresentation {

    var representation: [String : Any] {
        var rep: [String : Any] = [
            "created": sentDate,
            "createdAt": sentDate,
            "senderID": atcSender.uid ?? "",
            "senderFirstName": atcSender.firstName ?? "",
            "senderLastName": atcSender.lastName ?? "",
            "senderProfilePictureURL": atcSender.profilePictureURL ?? "",
            "recipientID": recipient.uid ?? "",
            "recipientFirstName": recipient.firstName ?? "",
            "recipientLastName": recipient.lastName ?? "",
            "recipientProfilePictureURL": atcSender.profilePictureURL ?? "",
            "readUserIDs": readUserIDs
        ]

        if let url = downloadURL {
            rep["url"] = ["url": url.absoluteString,
                          "mime": "image/jpeg"]
        } else if let url = audioDownloadURL {
            rep["url"] = ["url": url.absoluteString,
                          "mime": "audio/mp3",
                          "audioduration": audioDuration ?? 0.0]
        } else if let url = videoDownloadURL {
            rep["url"] = ["url": url.absoluteString,
                          "mime": "video/mp4",
                          "videoduration": videoDuration ?? 0.0 ,
                          "videothumbnailurl": videoThumbnailURL?.absoluteString ?? ""]
        } else {
            let attributedString = self.htmlContent?.fetchAttributedText(allTagUsers: self.allTagUsers)
            rep["content"] = attributedString
        }
        
        if let inReplyToMessage = inReplyToMessage {
            rep["inReplyToMessage"] = inReplyToMessage
        }
        if let inReplyToItem = inReplyToItem {
            rep["inReplyToItem"] = inReplyToItem.representation
        }
        return rep
    }

}

extension ATChatMessage: Comparable {

    static func == (lhs: ATChatMessage, rhs: ATChatMessage) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: ATChatMessage, rhs: ATChatMessage) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}

import Foundation

protocol DatabaseRepresentation {
    var representation: [String: Any] { get }
}
