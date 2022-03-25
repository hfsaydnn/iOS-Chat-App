//
//  ATCPostComposerState.swift
//  SocialNetwork
//
//  Created by Osama Naeem on 27/06/2019.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import UIKit

class ATCPostComposerState {    
    var postText: String? = nil
    var postMedia: [UIImage]? = []
    var postVideoPreview: [UIImage]? = []
    var postVideo: [URL]? = []
    var location: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var date: Date? = Date()
}
