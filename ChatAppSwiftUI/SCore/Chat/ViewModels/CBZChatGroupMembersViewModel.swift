//
//  CBZChatGroupMembersViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 19/04/21.
//

import SwiftUI
import FirebaseFirestore

class CBZChatGroupMembersViewModel: ObservableObject {
    @Published var showProgress: Bool = false
    @Published var groupMembers: [ATCUser] = []
    @Published var selectedFriends: [ATCUser] = []
    let socialManager = CBZFirebaseSocialGraphManager()
    var isChatApp: Bool = false
    
    init(isChatApp: Bool = false, viewer: ATCUser?) {
        self.isChatApp = isChatApp
        self.fetchFriends(viewer: viewer)
    }
    
    private func fetchFriends(viewer: ATCUser?) {
        guard let viewer = viewer else { return }

        showProgress = true
        if isChatApp {
            let socialManager = ATCFirebaseSocialGraphManager()
            socialManager.fetchFriends(viewer: viewer) { groupMembers in
                self.showProgress = false
                self.groupMembers = groupMembers
            }
        } else {
            self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: true) { (inBoundUsers) in
                self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: false) { (outBoundUsers) in
                    let inBoundAndOutBoundUsers = inBoundUsers.filter { (inBoundUser) -> Bool in
                        return outBoundUsers.contains(inBoundUser)
                    }
                    self.showProgress = false
                    self.groupMembers = inBoundAndOutBoundUsers
                }
            }
        }
    }
    
    func createChannel(creator: ATCUser?, completion: @escaping (_ channel: CBZChatChannel?) -> Void) {
        showProgress = true
        guard let creator = creator, let uid = creator.uid else { return }
        let channelParticipationRef = Firestore.firestore().collection("channel_participation")
        let channelsRef = Firestore.firestore().collection("channels")

        let allFriends = [creator] + Array(selectedFriends)
        let participantsDict = allFriends.map({ $0.representation })

        let newChannelRef = channelsRef.document()
        let channelDict: [String: Any] = [
            "id": newChannelRef.documentID,
            "channelID": newChannelRef.documentID,
            "creatorID": uid,
            "lastMessage": "No message",
            "name": "New Group",
            "participants": participantsDict,
        ]
        newChannelRef.setData(channelDict)

        var count = 0
        allFriends.forEach { (friend) in
            let doc: [String: Any] = [
                "channel": newChannelRef.documentID,
                "user": friend.uid ?? "",
                "isAdmin": friend.uid == creator.uid
            ]
            channelParticipationRef.addDocument(data: doc, completion: { (error) in
                count += 1
                if count == allFriends.count {
                    newChannelRef.getDocument(completion: { (snapshot, error) in
                        guard let snapshot = snapshot else { return }
                        completion(CBZChatChannel(document: snapshot))
                        self.showProgress = false
                    })
                }
            })
        }
    }
}
