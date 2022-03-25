//
//  CBZFeedPostNotification.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/05/21.
//

import Foundation

class CBZFeedPostNotification: ObservableObject, Identifiable {
    var postID: String
    var postAuthorID: String
    var notificationAuthorID: String
    var reacted: Bool
    var commented: Bool
    var isInteracted: Bool = false
    var notificationAuthorProfileImage: String
    var notificationAuthorUsername: String
    var createdAt: Date?
    var id: String
    
    var description: String {
        return postID
    }
    
    init(postID: String, notificationAuthorID: String, postAuthorID: String, reacted: Bool, commented: Bool, isInteracted: Bool, notificationAuthorProfileImage: String, notificationAuthorUsername: String, createdAt: Date, id: String) {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.notificationAuthorID = notificationAuthorID
        self.reacted = reacted
        self.commented = commented
        self.isInteracted = isInteracted
        self.notificationAuthorProfileImage = notificationAuthorProfileImage
        self.notificationAuthorUsername = notificationAuthorUsername
        self.createdAt = createdAt
        self.id = id
    }
    
    
    required init(jsonDict: [String : Any]) {
        self.postID = jsonDict["postID"] as? String ?? ""
        self.postAuthorID = jsonDict["postAuthorID"] as? String ?? ""
        self.notificationAuthorID = jsonDict["notificationAuthorID"] as? String ?? ""
        self.reacted = jsonDict["reacted"] as? Bool ?? false
        self.commented = jsonDict["commented"] as? Bool ?? false
        self.isInteracted = jsonDict["isInteracted"] as? Bool ?? false
        self.notificationAuthorProfileImage = jsonDict["notificationAuthorProfileImage"] as? String ?? ""
        self.notificationAuthorUsername = jsonDict["notificationAuthorUsername"] as? String ?? ""
        self.createdAt = jsonDict["createdAt"] as? Date ?? Date()
        self.id = jsonDict["id"] as? String ?? ""
    }
}
