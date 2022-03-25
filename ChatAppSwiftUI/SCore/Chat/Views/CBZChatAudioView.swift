//
//  CBZChatAudioView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 06/06/21.
//

import SwiftUI
import AVKit

struct CBZChatAudioView: View {
    @ObservedObject var viewModel: CBZChatAudioViewModel
    var appConfig: CBZConfigurationProtocol
    var uiConfig: CBZUIConfigurationProtocol
    var isFromSender: Bool
    
    init(message: CBZChatMessage, isFromSender: Bool, appConfig: CBZConfigurationProtocol, uiConfig: CBZUIConfigurationProtocol) {
        self.viewModel = CBZChatAudioViewModel(message: message)
        self.isFromSender = isFromSender
        self.appConfig = appConfig
        self.uiConfig = uiConfig
        if !self.viewModel.message.isAudioDownloading && !self.viewModel.message.isAudioDownloaded {
            if let audioDownloadURL = self.viewModel.message.audioDownloadURL {
                self.viewModel.downloadAudioFileFromURL(url: audioDownloadURL)
            }
        }
    }
    
    var body: some View {
        HStack {
            if viewModel.message.isAudioDownloaded {
                if self.viewModel.isSelected {
                    Button(action: {
                        self.viewModel.isSelected = false
                        self.viewModel.pauseAudioChat()
                    }) {
                        Image("pause")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(isFromSender ? Color.white : Color(uiConfig.mainTextColor))
                    }
                } else {
                    Button(action: {
                        self.viewModel.isSelected = true
                        if !self.viewModel.message.isAudioDownloading && !self.viewModel.message.isAudioDownloaded {
                            if let audioDownloadURL = self.viewModel.message.audioDownloadURL {
                                self.viewModel.downloadAudioFileFromURL(url: audioDownloadURL)
                            }
                        } else if self.viewModel.message.isAudioDownloaded {
                            self.viewModel.playAudioChat()
                        }
                    }) {
                        Image("play")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(isFromSender ? Color.white : Color(uiConfig.mainTextColor))
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isFromSender ? Color.white : Color(uiConfig.mainTextColor)))
                    .padding(.horizontal, 4)
                    .frame(width: 25, height: 25)
            }
            CustomSliderView(currentValue: $viewModel.sliderValue, totalValue: Double(viewModel.currentAudioMessageDuration), fillColor: UIColor(hexString: "#B3B3B3"))
                .accentColor(isFromSender ? Color.white : Color(uiConfig.mainTextColor))
                .frame(width: 120)
                .padding(.top, 7)
            Text(viewModel.audioDurationText)
                .font(uiConfig.regularFont(size: 12))
                .foregroundColor(isFromSender ? Color.white : Color(uiConfig.mainTextColor))
                .frame(width: 30)
        }.frame(width: 195, height: 25)
    }
}

struct CustomSliderView: View {
    
    @Binding var currentValue: Double
    var totalValue: Double
    var fillColor: UIColor
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color(fillColor))
                    .frame(height: 6)
                    .cornerRadius(3)
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: geometry.size.width * CGFloat((currentValue/totalValue) * 100) / 100, height: 6)
                    .cornerRadius(3)
                let calculatedPadding = geometry.size.width * CGFloat(currentValue/totalValue)
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: 10, height: 10)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .padding(.leading, (calculatedPadding + 10 > geometry.size.width ? geometry.size.width - 10 : (calculatedPadding > 0 ? calculatedPadding - 5 : 0)))
            }
        }
    }
}
