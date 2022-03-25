//
//  CBZChatAudioRecordView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 06/06/21.
//

import SwiftUI

struct CBZChatAudioRecordView: View {
    @StateObject var viewModel: CBZChatAudioRecordViewModel
    @ObservedObject var chatThreadViewModel: CBZChatThreadViewModel

    init(user: ATCUser?, channel: CBZChatChannel, showRecordView: Binding<Bool>, showLoader: Binding<Bool>, chatThreadViewModel: CBZChatThreadViewModel) {
        _viewModel = StateObject(wrappedValue: CBZChatAudioRecordViewModel(user: user,
                                                                           channel: channel,
                                                                           showRecordView: showRecordView,
                                                                           showLoader: showLoader))
        self.chatThreadViewModel = chatThreadViewModel
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text(viewModel.timerString)
            Spacer()
            HStack {
                if viewModel.isRecordStarted {
                    Button(action: {
                        viewModel.isRecordStarted.toggle()
                        viewModel.cancelAudioRecord()
                    }) {
                        Text("Cancel".localizedCore)
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .contentShape(Rectangle())
                    }
                    .frame(height: 45)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom], 10)

                    Button(action: {
                        chatThreadViewModel.resetReplyingItem()
                        viewModel.isRecordStarted.toggle()
                        viewModel.sendAudioRecord()
                    }) {
                        Text("Send".localizedThirdParty)
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .contentShape(Rectangle())
                    }
                    .frame(height: 45)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom], 10)
                } else {
                    Button(action: {
                        viewModel.isRecordStarted.toggle()
                        viewModel.startAudioRecord()
                    }) {
                        Text("Record".localizedThirdParty)
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .contentShape(Rectangle())
                    }
                    .frame(height: 45)
                    .background(Color.red)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom], 10)
                }
            }
        }
    }
}
