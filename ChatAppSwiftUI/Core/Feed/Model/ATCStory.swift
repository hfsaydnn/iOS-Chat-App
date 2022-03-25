//
//  ATCStory.swift
//  SocialNetwork
//
//  Created by Osama Naeem on 18/06/2019.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import UIKit

class ATCStory : ATCGenericBaseModel{

    var description: String {
        return "Story"
    }
    
    var storyType: String
    var storyMediaURL: String
    var storyAuthorID: String
    var createdAt: Date

    
    init(storyType: String, storyMediaURL: String, storyAuthorID: String, createdAt: Date) {
        self.storyType = storyType
        self.storyMediaURL = storyMediaURL
        self.storyAuthorID = storyAuthorID
        self.createdAt = createdAt
    }
    
    required init(jsonDict: [String : Any]) {
        self.storyType = (jsonDict["storyType"] as? String) ?? ""
        self.storyMediaURL = (jsonDict["storyMediaURL"] as? String) ?? ""
        self.storyAuthorID = (jsonDict["storyAuthorID"] as? String) ?? ""
        self.createdAt = (jsonDict["createdAt"] as?  Date) ?? Date()
    }
    
    
}
