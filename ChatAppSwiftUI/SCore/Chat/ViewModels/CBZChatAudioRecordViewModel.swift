//
//  CBZChatAudioRecordViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 06/06/21.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AVKit

struct kAudioRecordingConfig {
    static let kAudioMessageTimeLimit: TimeInterval = 59.0
}

class CBZChatAudioRecordViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate, SocialFeedsChatFeedUpdateProtocol {
    @Published var timerString: String = "0:00"
    @Published var isRecordStarted: Bool = false
    @Binding var showRecordView: Bool
    @Binding var showLoader: Bool

    var recordingSession: AVAudioSession? = nil
    var audioRecorder: AVAudioRecorder? = nil

    var audioRecordingTimeLeft: Double = 0.0
    var audioRecordingTimer: Timer? = nil
    var isSendingMedia = false
    
    private let storage = Storage.storage().reference()
    var channel: CBZChatChannel
    var user: ATCUser?
    private var reference: CollectionReference?
    private let db = Firestore.firestore()

    init(user: ATCUser?, channel: CBZChatChannel, showRecordView: Binding<Bool>, showLoader: Binding<Bool>) {
        self.user = user
        self.channel = channel
        self._showRecordView = showRecordView
        self._showLoader = showLoader
        reference = db.collection(["channels", channel.id, "thread"].joined(separator: "/"))
    }
    
    func startAudioRecord() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            recordingSession?.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                        self.audioRecordingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.onTimerFires), userInfo: nil, repeats: true)
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    private func startRecording() {
        audioRecordingTimeLeft = 0.0
        let audioFilename = documentDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            finishRecording(success: false)
        }
    }
    
    func sendAudioRecord() {
        timerString = "0:00"
        if let audioRecordingTimer = audioRecordingTimer {
            self.stopTimer(audioRecordingTimer)
        }
        finishRecording(success: true)
    }
    
    func cancelAudioRecord() {
        timerString = "0:00"
        if let audioRecordingTimer = audioRecordingTimer {
            self.stopTimer(audioRecordingTimer)
        }
        finishRecording(success: false)
    }
    
    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        
        showRecordView = false
        guard let user = user else {
            return
        }
        if success {
            let audioFileUrl = documentDirectory().appendingPathComponent("recording.m4a")
            isSendingMedia = true
            uploadMediaMessage(audioFileUrl, to: channel) { [weak self] url in
                
                guard let `self` = self else {
                    return
                }
                self.isSendingMedia = false

                guard let url = url else {
                    return
                }
                
                let asset = AVURLAsset(url: audioFileUrl, options: nil)
                let audioDuration = asset.duration
                let audioDurationSeconds = CMTimeGetSeconds(audioDuration)

                let message = ATChatMessage(user: user, audioURL: url, audioDuration: Float(audioDurationSeconds))
                message.audioDownloadURL = url
                message.readUserIDs = [user.uid ?? ""]
                self.save(message, user: self.user, channel: self.channel)
            }
        }
    }
    
    @objc func onTimerFires()
    {
        audioRecordingTimeLeft += 1.0

        let currentTime = Int(audioRecordingTimeLeft)
        let minutes = currentTime/60
        let seconds = currentTime - minutes * 60
            
        timerString = String(format: "%2d:%02d", minutes,seconds)

        if audioRecordingTimeLeft >= kAudioRecordingConfig.kAudioMessageTimeLimit {
            if let audioRecordingTimer = audioRecordingTimer {
                self.stopTimer(audioRecordingTimer)
            }
        }
    }
    
    func stopTimer(_ timer: Timer) {
        timer.invalidate()
    }
    
    func documentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    private func uploadMediaMessage(_ url: URL, to channel: CBZChatChannel, completion: @escaping (URL?) -> Void) {
        
        showLoader = true
        
        let fileName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        storage.child(channel.id).child(fileName).putFile(from: url, metadata: nil) { (meta, error) in
            self.showLoader = false
            if let name = meta?.path, let bucket = meta?.bucket {
                let path = "gs://" + bucket + "/" + name
                completion(URL(string: path))
            } else {
                completion(nil)
            }
        }
    }
    
    private func save(_ message: ATChatMessage, allTagUsers: [String] = [], user: ATCUser?, channel: CBZChatChannel) {
        guard let user = user, let userID = user.uid else { return }
        let messageWithParticipants = channel.addParticipants(userID: userID, message: message)
        reference?.addDocument(data: messageWithParticipants.dict) {[weak self] error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            guard let `self` = self else { return }

            self.updateLastMessage(userID: userID, channel: channel, channelID: channel.id, message: message, allTagUsers: allTagUsers, participantProfilePictureURLs: messageWithParticipants.picUrls)
            self.updateChannelParticipationIfNeeded(channel: channel)
            self.sendOutPushNotificationsIfNeeded(message: message, user: user, channel: channel)
        }
    }
    
    private func sendOutPushNotificationsIfNeeded(message: ATChatMessage, user: ATCUser?, channel: CBZChatChannel) {
        var lastMessage = ""
        let senderName = user?.firstName ?? "Someone"
        switch message.kind {
        case let .text(text):
            lastMessage = text
        case let .attributedText(text, text1):
            lastMessage = text.string
        case .photo:
            lastMessage = "\(senderName) sent you a photo."
        case .audio:
            lastMessage = "\(senderName) sent you an audio message."
        case .video:
            lastMessage = "\(senderName) sent you a video message."
        default:
            break
        }

        let notificationSender = ATCPushNotificationSender()
        channel.participants.forEach { (recipient) in
            if let token = recipient.pushToken, recipient.uid != user?.uid {
                notificationSender.sendPushNotification(token: token,
                                                        title: user?.firstName ?? "Instachatty",
                                                        body: lastMessage,
                                                        notificationType: .chatAppNewMessage,
                                                        payload: ["channelId" : channel.id])
            }
        }
    }
    
    func updateChannelParticipationIfNeeded(channel: CBZChatChannel) {
        if channel.participants.count != 2 {
            return
        }
        guard let uid1 = channel.participants.first?.uid, let uid2 = channel.participants[1].uid else { return }
        self.updateChannelParticipationIfNeeded(channel: channel, uID: uid1)
        self.updateChannelParticipationIfNeeded(channel: channel, uID: uid2)
    }
    
    private func updateChannelParticipationIfNeeded(channel: CBZChatChannel, uID: String) {
        let ref1 = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uID).whereField("channel", isEqualTo: channel.id)
        ref1.getDocuments { (querySnapshot, error) in
            if (querySnapshot?.documents.count == 0) {
                let data: [String: Any] = [
                    "user": uID,
                    "channel": channel.id
                ]
                Firestore.firestore().collection("channel_participation").addDocument(data: data, completion: nil)
            }
        }
    }
}
