//
//  CBZPostComment.swift
//  SocialNetwork
//
//  Created by Osama Naeem on 01/07/2019.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import UIKit

class CBZPostComment: ObservableObject, Identifiable {
    let id = UUID()
    var commentAuthorUsername: String?
    var commentAuthorProfilePicture: String?
    var commentText: String?
    var createdAt: Date?
    
    var description: String {
        return "ATC Comment"
    }
    
    init(commentAuthorUsername: String, commentAuthorProfilePicture: String, commentText: String, createdAt: Date) {
        self.commentText = commentText
        self.commentAuthorUsername = commentAuthorUsername
        self.commentAuthorProfilePicture = commentAuthorProfilePicture
        self.createdAt = createdAt
    }
    
    
    required init(jsonDict: [String : Any]) {
        self.commentText = (jsonDict["commentText"] as? String) ?? ""
        self.commentAuthorProfilePicture = (jsonDict["commentAuthorProfilePicture"] as? String) ?? ""
        self.commentAuthorUsername = (jsonDict["commentAuthorUsername"] as? String) ?? ""
        self.createdAt = (jsonDict["createdAt"] as? Date) ?? Date()
    }
    
}
