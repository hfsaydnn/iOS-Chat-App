//
//  ATCGenericBaseModelProtocol.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 12/04/21.
//

import UIKit

protocol ATCGenericJSONParsable {
    init(jsonDict: [String: Any])
}

protocol ATCGenericBaseModel: ATCGenericJSONParsable, CustomStringConvertible {
}
