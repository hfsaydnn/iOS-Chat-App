//
//  CBZChatMessage.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 25/04/21.
//

import SwiftUI
import AVKit

class CBZChatMessage: ATChatMessage, ObservableObject, Identifiable {
    @Published var downloadURLCompleted: Bool = false
    @Published var isAudioDownloaded: Bool = false
    @Published var isAudioDownloading: Bool = false
    @Published var audioPlayer: AVAudioPlayer? = nil
}
