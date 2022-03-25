//
//  ATCChatFriendship.swift
//  ChatApp
//
//  Created by Florian Marcu on 6/5/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import UIKit

enum ATCFriendshipType {
    case mutual
    case inbound
    case outbound
}

class ATCChatFriendship: NSObject, ATCGenericBaseModel {

    var currentUser: ATCUser
    var otherUser: ATCUser
    var type: ATCFriendshipType
    var id = UUID()

    override var description: String {
        return currentUser.description + otherUser.description + String(type.hashValue)
    }

    init(currentUser: ATCUser, otherUser: ATCUser, type: ATCFriendshipType) {
        self.currentUser = currentUser
        self.otherUser = otherUser
        self.type = type
    }

    required public init(jsonDict: [String: Any]) {
        fatalError()
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let friendship = object as? ATCChatFriendship else { return false }
        return self.id == friendship.id
    }
}
