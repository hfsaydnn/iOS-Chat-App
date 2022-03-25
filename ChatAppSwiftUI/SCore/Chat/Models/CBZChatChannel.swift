//
//  CBZChatChannel.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/26/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import FirebaseFirestore

class CBZChatChannel: ObservableObject, Identifiable {
    var description: String {
        return id
    }

    let id: String
    let name: String
    let lastMessageDate: Date
    var participants: [ATCUser]
    let lastMessage: String
    let groupCreatorID: String
    var readUserIDs: [String]
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.participants = []
        self.lastMessageDate = Date().oneYearAgo
        self.lastMessage = ""
        self.groupCreatorID = ""
        self.readUserIDs = []
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        var name: String = ""
        if let tmp = data["name"] as? String {
            name = tmp
        }
        self.id = document.documentID
        self.name = name
        self.participants = []

        var date = Date().oneYearAgo
        if let d = data["lastMessageDate"] as? Timestamp {
            date = d.dateValue()
        }
        self.lastMessageDate = date
        var lastMessage = ""
        if let m = data["lastMessage"] as? String {
            lastMessage = m
        }
        var creatorID = ""
        if let id = data["creatorID"] as? String {
            creatorID = id
        }
        self.readUserIDs = []
        if let readUserIDs = data["readUserIDs"] as? [String] {
            self.readUserIDs = readUserIDs
        }
        self.groupCreatorID = creatorID
        self.lastMessage = lastMessage
    }

    init(jsonDict: [String: Any]) {
        fatalError()
    }
    
    func addParticipants(userID: String, message: ATChatMessage) -> (dict: [String: Any], picUrls: [[String: String]]) {
        let otherParticipants = participants.filter({ $0.uid != userID })
        let participantProfilePictureURLs = otherParticipants.map({ ["participantId": $0.uid ?? "",
                                                                     "profilePictureURL": $0.profilePictureURL ?? ""] })
        var message = message.representation
        message["participantProfilePictureURLs"] = participantProfilePictureURLs
        return (message, participantProfilePictureURLs)
    }
}

extension CBZChatChannel: DatabaseRepresentation {
    var representation: [String : Any] {
        var rep = ["name": name]
        rep["id"] = id
        return rep
    }
}

extension CBZChatChannel: Comparable {

    static func == (lhs: CBZChatChannel, rhs: CBZChatChannel) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: CBZChatChannel, rhs: CBZChatChannel) -> Bool {
        return lhs.name < rhs.name
    }

}
