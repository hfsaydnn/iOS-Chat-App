//
//  CBZConfigurationProtocol.swift
//  SCore
//
//  Created by Mayil Kannan on 04/03/21.
//

protocol CBZConfigurationProtocol {
    var appIdentifier: String { get set }

    var isFirebaseAuthEnabled: Bool { get set }
    
    var walkthroughData: [CBZWalkthroughModel] { get set }
}
