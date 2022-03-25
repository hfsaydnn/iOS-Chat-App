//
//  CBZPostModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 12/04/21.
//

import UIKit
import AVKit

class CBZPostModel: ObservableObject, Identifiable {
//    let id = UUID()
    
    var postUserName: String?
    var postText: String
    var postLikes: Int
    var postComment: Int
    var postMedia: [String]
    var postMediaType: [String]
    var postReactions: [String: Int] = [:]
    var profileImage: String
    var authorID: String?
    var createdAt: Date?
    var location: String?
    var id: String
    var latitude: Double? = nil
    var longitude: Double? = nil
    var selectedReaction: String? = nil {
        didSet {
            if let selectedReaction = selectedReaction {
                isSelectedReaction = (!selectedReaction.isEmpty && selectedReaction != "no_reaction")
            } else {
                isSelectedReaction = false
            }
        }
    }
    @Published var isSelectedReaction: Bool = false
    @Published var player: [Int: AVPlayer] = [:]
    @Published var player1: [Int: AVPlayer] = [:]
    @Published var isVisible: Bool = false
    @Published var isVideoStartPlay: [Int: Bool] = [:]
    @Published var isVideoStartPlay1: [Int: Bool] = [:]

    var postVideoPreview: [String]
    var postVideo: [String]

    var description: String {
        return "ATCUser post"
    }
    
    var dateAsString: String {
        //Formatting Date
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "d MMM yyyy HH:mm"
        if let date = self.createdAt {
            let stringDate = TimeFormatHelper.timeAgoString(date: date)
            return stringDate
        }
        return ""
    }
    
    // Creating an ATCPost in new post VC using this initializer
    init(postUserName: String, postText: String, postLikes: Int, postComment: Int, postMedia: [String], postMediaType: [String], profileImage: String, createdAt: Date?, authorID: String, location: String, id: String, latitude: Double, longitude: Double, postReactions: [String: Int], selectedReaction: String, postVideoPreview: [String], postVideo: [String]) {
        self.postUserName = postUserName
        self.postText = postText
        self.postLikes = postLikes
        self.postComment = postComment
        self.postMedia = postMedia
        self.postMediaType = postMediaType
        self.profileImage = profileImage
        self.createdAt = createdAt
        self.authorID = authorID
        self.location = location
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.postReactions = postReactions
        self.selectedReaction = selectedReaction
        self.postVideoPreview = postVideoPreview
        self.postVideo = postVideo
    }
    
    // When creating a post from data fetched from firebase
    required init(jsonDict: [String: Any]) {
        self.authorID = jsonDict["authorID"] as? String ?? ""
        if let postMedias = jsonDict["postMedia"] as? [[String: Any]] {
            var postUrls: [String] = []
            var postMediaType:[String] = []
            for postMedia in postMedias {
                if let url = postMedia["url"] as? String {
                    postUrls.append(url)
                }
                if let mime = postMedia["mime"] as? String {
                    postMediaType.append(mime)
                }
            }
            self.postMedia = postUrls
            self.postMediaType = postMediaType
        } else if let postMedia = jsonDict["postMedia"] as? [String: Any] {
            var postUrls: [String] = []
            var postMediaType:[String] = []
            if let url = postMedia["url"] as? String {
                postUrls.append(url)
            }
            if let mime = postMedia["mime"] as? String {
                postMediaType.append(mime)
            }
            self.postMedia = postUrls
            self.postMediaType = postMediaType
        } else {
            self.postMedia = jsonDict["postMedia"] as? [String] ?? []
            self.postMediaType = []
        }
        self.postText = jsonDict["postText"] as? String ?? ""
        self.createdAt = jsonDict["createdAt"] as? Date ?? Date()
        if let reactionsCount = jsonDict["reactionsCount"] as? Int, reactionsCount != 0 {
            self.postLikes = reactionsCount
        } else {
            self.postLikes = (jsonDict["postLikes"] as? Int) ?? 0
        }
        self.postComment = (jsonDict["commentCount"] as? Int) ?? 0
        if let authorData = jsonDict["author"] as? [String: Any] {
            self.postUserName = (authorData["username"] as? String) ?? ""
            self.profileImage = (authorData["profilePictureURL"] as? String) ?? ""
        } else {
            self.postUserName = (jsonDict["postUserName"] as? String) ?? ""
            self.profileImage = (jsonDict["profileImage"] as? String) ?? ""
        }
        self.location = (jsonDict["location"] as? String) ?? "San Francisco"
        self.id = (jsonDict["id"] as? String) ?? ""
        self.longitude = (jsonDict["longitude"] as? Double) ?? 0.0
        self.latitude = (jsonDict["latitude"] as? Double) ?? 0.0
        self.postReactions = (jsonDict["reactions"] as? [String: Int]) ?? [:]
        self.selectedReaction = (jsonDict["selectedReaction"] as? String) ?? ""
        self.postVideoPreview = jsonDict["postVideoPreview"] as? [String] ?? []
        self.postVideo = jsonDict["postVideo"] as? [String] ?? []
    }
}

class CBZPostReactionStatus: ObservableObject {
    var reaction: String?
    var postID: String?
    var reactionAuthorID: String?
    
    init(reaction: String, postID: String, reactionAuthorID: String) {
        self.reaction = reaction
        self.postID = postID
        self.reactionAuthorID = reactionAuthorID
    }
    
    required init(jsonDict: [String: Any]) {
        self.reaction = jsonDict["reaction"] as? String ?? ""
        self.postID = jsonDict["postID"] as? String ?? ""
        self.reactionAuthorID = jsonDict["reactionAuthorID"] as? String ?? ""
    }
}
