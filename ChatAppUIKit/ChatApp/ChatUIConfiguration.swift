//
//  ChatUIConfiguration.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/18/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import UIKit

class ChatUIConfiguration: ATCUIGenericConfigurationProtocol {
    let colorGray0: UIColor = UIColor.darkModeColor(hexString: "#000000")
    let colorGray3: UIColor = UIColor.darkModeColor(hexString: "#333333")
    let colorGray9: UIColor = UIColor.darkModeColor(hexString: "#f4f4f4")

    let mainThemeBackgroundColor: UIColor = UIColor.modedColor(light: "#ffffff", dark: "#121212")
    let mainThemeForegroundColor: UIColor = UIColor(hexString: "#3068CC")
    let mainTextColor: UIColor = UIColor.darkModeColor(hexString: "#000000")
    let mainSubtextColor: UIColor = UIColor.darkModeColor(hexString: "#7e7e7e")
    let statusBarStyle: UIStatusBarStyle = .default
    let hairlineColor: UIColor =  UIColor.darkModeColor(hexString: "#d6d6d6")

    let regularSmallFont = UIFont.systemFont(ofSize: 14)
    let regularMediumFont = UIFont.systemFont(ofSize: 17)
    let regularLargeFont = UIFont.systemFont(ofSize: 23)
    let mediumBoldFont = UIFont.boldSystemFont(ofSize: 17)
    let boldLargeFont = UIFont.boldSystemFont(ofSize: 23)
    let boldSmallFont = UIFont.boldSystemFont(ofSize: 14)
    let boldSuperSmallFont = UIFont.boldSystemFont(ofSize: 11)
    let boldSuperLargeFont = UIFont.boldSystemFont(ofSize: 29)

    let italicMediumFont = UIFont.italicSystemFont(ofSize: 17)

    func regularFont(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }

    func boldFont(size: CGFloat) -> UIFont {
        return UIFont.boldSystemFont(ofSize: size)
    }
    
    func lightFont(size: CGFloat) -> UIFont {
        return UIFont.italicSystemFont(ofSize: size)
    }

    func configureUI() {
        UITabBar.appearance().barTintColor = UIColor.modedColor(light: "#fefefe", dark: "#121212") // self.mainThemeBackgroundColor
        UITabBar.appearance().tintColor = UIColor.darkModeColor(hexString: "#000000")
        UITabBar.appearance().unselectedItemTintColor = UIColor.darkModeColor(hexString: "#a5aab0")
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor : UIColor.darkModeColor(hexString: "#a5aab0"),
                                                          .font: self.boldSuperSmallFont],
                                                         for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor : self.mainThemeBackgroundColor,
                                                          .font: self.boldSuperSmallFont],
                                                         for: .selected)

        UITabBar.appearance().backgroundImage = UIImage.colorForNavBar(UIColor.modedColor(light: "#fefefe", dark: "#121212"))
        UITabBar.appearance().shadowImage = UIImage.colorForNavBar(UIColor.modedColor(light: "#f8f8f8", dark: "#121212"))

        UINavigationBar.appearance().barTintColor = self.mainThemeBackgroundColor
        UINavigationBar.appearance().tintColor = self.mainThemeForegroundColor
        //
        //        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: ATCUIConfiguration.shared.navigationBarTitleColor]
        //        UINavigationBar.appearance().isTranslucent = false
        //
        //        UITabBar.appearance().tintColor = ATCUIConfiguration.shared.mainThemeColor
        //        UITabBar.appearance().barTintColor = ATCUIConfiguration.shared.tabBarBarTintColor
        //        if #available(iOS 10.0, *) {
        //            UITabBar.appearance().unselectedItemTintColor = ATCUIConfiguration.shared.mainThemeColor
        //        }
    }
    
    func configureTabBarUI(tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor.modedColor(light: "#fefefe", dark: "#121212")
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.darkModeColor(hexString: "#000000")
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.darkModeColor(hexString: "#a5aab0")
        tabBar.standardAppearance = appearance
    }
}
