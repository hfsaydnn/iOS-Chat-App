//
//  ChatAppUIConfiguration.swift
//  ChatApp
//
//  Created by Mayil Kannan on 31/08/21.
//

import SwiftUI

class ChatAppUIConfiguration: CBZUIConfigurationProtocol {
    var mainThemeForegroundColor: UIColor = UIColor(hexString: "#4991ec")
    var mainTextColor: UIColor = UIColor.darkModeColor(hexString: "#151723")
    var mainSubtextColor: UIColor = UIColor.darkModeColor(hexString: "#7e7e7e")
    var grey1: UIColor = UIColor.darkModeColor(hexString: "#F5F5F5")
    var grey2: UIColor = UIColor.darkModeColor(hexString: "808080")
    var grey3: UIColor = UIColor.darkModeColor(hexString: "#e6e6f2")
    
    let regularSmallFont = Font.system(size: 14)
    let regularMediumFont = Font.system(size: 17)
    let regularLargeFont = Font.system(size: 23)
    
    let semiBoldFont = Font.system(size: 17, weight: .semibold)
    
    let boldSuperLargeFont = Font.system(size: 30, weight: .bold)
    
    func regularFont(size: CGFloat) -> Font {
        Font.system(size: size)
    }
    
    func mediumFont(size: CGFloat) -> Font {
        Font.system(size: size, weight: .medium)
    }
    
    func boldFont(size: CGFloat) -> Font {
        Font.system(size: size, weight: .bold)
    }
}
