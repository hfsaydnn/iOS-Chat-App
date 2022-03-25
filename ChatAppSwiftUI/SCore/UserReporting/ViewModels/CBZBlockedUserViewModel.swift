//
//  CBZBlockedUserViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 30/05/21.
//

import SwiftUI
import FirebaseFirestore

class CBZBlockedUserViewModel: ObservableObject {
    
    @Published var isBlockedUsersFetching: Bool = false
    @Published var blockedUsers: [ATCUser] = []
    var loggedInUser: ATCUser? = nil
    let reportingManager = ATCFirebaseUserReporter()
    let userManager = ATCSocialFirebaseUserManager()

    init(loggedInUser: ATCUser?) {
        self.loggedInUser = loggedInUser
    }
    
    func fetchBlockedUsers() {
        guard let user = loggedInUser else { return }
        isBlockedUsersFetching = true
        reportingManager.userIDsBlockedOrReported(by: user) {[weak self] illegalUserIDsSet in
            var illegalUserIDsFetchCount = illegalUserIDsSet.count
            var allBlockedUsers: [ATCUser] = []
            if illegalUserIDsFetchCount == 0 {
                self?.isBlockedUsersFetching = false
            }
            illegalUserIDsSet.forEach {
                self?.userManager.fetchUser(userID: $0) {[weak self] user, error in
                    illegalUserIDsFetchCount -= 1
                    guard let user = user else {
                        if illegalUserIDsFetchCount == 0 {
                            self?.blockedUsers = allBlockedUsers
                            self?.isBlockedUsersFetching = false
                        }
                        return
                    }
                    allBlockedUsers.append(user)
                    if illegalUserIDsFetchCount == 0 {
                        self?.blockedUsers = allBlockedUsers
                        self?.isBlockedUsersFetching = false
                    }
                }
            }
        }
    }
    
    func unBlockUser(unBlockUser: ATCUser) {
        guard let user = loggedInUser else { return }
        guard let id = user.uid else { return }
        guard let unBlockUserID = unBlockUser.uid else { return }
        
        let blocksRef = Firestore.firestore().collection("blocks")
        let sourceBlocksRef = blocksRef
            .whereField("source", isEqualTo: id)
            .whereField("dest", isEqualTo: unBlockUserID)
        sourceBlocksRef.getDocuments {(querySnapshot, error) in
            if error != nil {
                return
            }
            guard let querySnapshot = querySnapshot else {
                return
            }
            let documents = querySnapshot.documents
            for document in documents {
                blocksRef.document(document.documentID).delete()
            }
        }
        
        let reportsRef = Firestore.firestore().collection("reports")
        let sourceReportsRef = reportsRef
            .whereField("source", isEqualTo: id)
            .whereField("dest", isEqualTo: unBlockUserID)
        sourceReportsRef.getDocuments {(querySnapshot, error) in
            if error != nil {
                return
            }
            guard let querySnapshot = querySnapshot else {
                return
            }
            let documents = querySnapshot.documents
            for document in documents {
                reportsRef.document(document.documentID).delete()
            }
        }
        
        blockedUsers = blockedUsers.filter({ $0.uid != unBlockUserID })
    }
}
