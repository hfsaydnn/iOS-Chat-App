//
//  ChatServerConfiguration.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/18/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import UIKit

class ChatServerConfiguration: ATCOnboardingServerConfigurationProtocol {
    var isInstagramIntegrationEnabled: Bool = false
    
    var appIdentifier: String = "chat-swift-ios"

    var isFirebaseAuthEnabled: Bool = true
    var isFirebaseDatabaseEnabled: Bool = true
    
    var isPhoneAuthEnabled: Bool = true
    
    var isAudioMessagesEnabled: Bool = true
}


class ChatServiceConfig: ATCChatServiceConfigProtocol {
    var emptyViewTitleButton: String = "No Messages"
    var emptyViewDescription: String = "You did not message anyone yet. Add friends and start conversations with them. Your messages will show up here."
    var isAudioMessagesEnabled = true
    
    var isVideoCallingEnabled = true
    var isAudioCallingEnabled = true
    
    func isAudioVideoCallEnabled() -> Bool {
        return (isAudioCallingEnabled || isVideoCallingEnabled)
    }
    var isTypingIndicatorEnabled = true
    
    var showOnlineStatus = true
    var showLastSeen = true
}
