//
//  ChatAppConfiguration.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 04/03/21.
//

import UIKit

class ChatAppConfiguration: CBZConfigurationProtocol {
    
    // MARK: - App configuration part
    var appIdentifier: String = "instagram-swiftui-ios"

    var isFirebaseAuthEnabled: Bool = true
    
    var walkthroughData = [
        CBZWalkthroughModel(title: "Private Messages", subtitle: "Communicate with your friends via private messages.", icon: "private-chat-icon-1"),
        CBZWalkthroughModel(title: "Group Chats", subtitle: "Create group chats and stay in touch with your gang.", icon: "walkthrough-friends-icon"),
        CBZWalkthroughModel(title: "Send Photos & Videos", subtitle: "Have fun with your friends by sending photos and videos to each other.", icon: "camera-walkthrough-icon"),
        CBZWalkthroughModel(title: "Get Notified", subtitle: "Receive notifications when your friends are looking for you.", icon: "notification"),
    ]
    
}

