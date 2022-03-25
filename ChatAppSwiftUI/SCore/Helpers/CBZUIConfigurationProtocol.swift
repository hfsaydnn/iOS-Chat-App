//
//  CBZUIConfigurationProtocol.swift
//  ChatApp
//
//  Created by Mayil Kannan on 31/08/21.
//

import SwiftUI

protocol CBZUIConfigurationProtocol {
    var mainThemeForegroundColor: UIColor { get set }
    var mainTextColor: UIColor { get set }
    var mainSubtextColor: UIColor { get set }
    var grey1: UIColor { get set }
    var grey2: UIColor { get set }
    var grey3: UIColor { get set }
    
    var regularSmallFont: Font {get}
    var regularMediumFont: Font {get}
    var regularLargeFont: Font {get}
    
    var semiBoldFont: Font {get}
    
    var boldSuperLargeFont: Font {get}

    func regularFont(size: CGFloat) -> Font
    
    func mediumFont(size: CGFloat) -> Font

    func boldFont(size: CGFloat) -> Font
}
