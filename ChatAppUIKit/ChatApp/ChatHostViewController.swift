//
//  ChatHostViewController.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/18/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import UIKit

class ChatHostViewController: UIViewController, UITabBarControllerDelegate {

    let homeVC: ATCChatHomeViewController
    let profileVC : ATCChatProfileViewController
    let contactVC : ATCFriendsCollectionViewController
    let uiConfig: ATCUIGenericConfigurationProtocol
    let serverConfig: ChatServerConfiguration
    var viewer: ATCUser? = nil
    let profileManager: ATCProfileManager?
    let reportingManager: ATCUserReportingProtocol?
    let chatServiceConfig: ATCChatServiceConfigProtocol
    var onlinePresenceTracker: ATCOnlinePresenceTracker? = nil
    
    init(uiConfig: ATCUIGenericConfigurationProtocol,
         serverConfig: ChatServerConfiguration,
         chatServiceConfig: ATCChatServiceConfigProtocol,
         threadsDataSource: ATCGenericCollectionViewControllerDataSource,
         profileManager: ATCProfileManager?,
         userSearchDataSource: ATCGenericSearchViewControllerDataSource,
         reportingManager: ATCUserReportingProtocol?) {
        self.uiConfig = uiConfig
        self.serverConfig = serverConfig
        self.chatServiceConfig = chatServiceConfig
        self.profileManager = profileManager
        self.reportingManager = reportingManager
        self.homeVC = ATCChatHomeViewController.homeVC(uiConfig: uiConfig,
                                                       threadsDataSource: threadsDataSource,
                                                       userSearchDataSource: userSearchDataSource,
                                                       chatServiceConfig: chatServiceConfig,
                                                       reportingManager: reportingManager)
        self.contactVC = ATCFriendsCollectionViewController(uiConfig: uiConfig,
                                                            chatServiceConfig: chatServiceConfig,
                                                            reportingManager: reportingManager)
        self.profileVC = ATCChatProfileViewController(uiConfig: uiConfig,
                                                      profileManager: profileManager)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var hostController: ATCHostViewController = { [unowned self] in
        let menuItems: [ATCNavigationItem] = [
            ATCNavigationItem(title: nil,
                              viewController: homeVC,
                              image: UIImage.localImage("bubble-chat-glyph-icon", template: true),
                              type: .viewController,
                              leftTopViews: nil,
                              rightTopViews: [self.newMessageButton()]),
            ATCNavigationItem(title: nil,
                              viewController: contactVC,
                              image: UIImage.localImage("friends-glyph-icon", template: true),
                              type: .viewController,
                              leftTopViews: nil,
                              rightTopViews: nil),
            ATCNavigationItem(title: nil,
                              viewController: profileVC,
                              image: UIImage.localImage("profile-glyph-icon", template: true),
                              type: .viewController,
                              leftTopViews: nil,
                              rightTopViews: nil)
        ]
        let menuConfiguration = ATCMenuConfiguration(user: nil,
                                                     cellClass: ATCCircledIconMenuCollectionViewCell.self,
                                                     headerHeight: 0,
                                                     items: menuItems,
                                                     uiConfig: ATCMenuUIConfiguration(itemFont: uiConfig.regularMediumFont,
                                                                                      tintColor: uiConfig.mainTextColor,
                                                                                      itemHeight: 45.0,
                                                                                      backgroundColor: uiConfig.mainThemeBackgroundColor))

        let config = ATCHostConfiguration(menuConfiguration: menuConfiguration,
                                          style: .tabBar,
                                          topNavigationRightViews: nil,
                                          titleView: nil,
                                          topNavigationLeftImage: UIImage.localImage("three-equal-lines-icon", template: true),
                                          topNavigationTintColor: uiConfig.mainThemeForegroundColor,
                                          statusBarStyle: uiConfig.statusBarStyle,
                                          uiConfig: uiConfig,
                                          pushNotificationsEnabled: true,
                                          locationUpdatesEnabled: false)
        let onboardingCoordinator = self.onboardingCoordinator(uiConfig: uiConfig)
        let walkthroughVC = self.walkthroughVC(uiConfig: uiConfig)
        return ATCHostViewController(configuration: config, onboardingCoordinator: onboardingCoordinator, walkthroughVC: walkthroughVC, profilePresenter: nil)
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        hostController.delegate = self
        self.addChildViewControllerWithView(hostController)
        hostController.view.backgroundColor = uiConfig.mainThemeBackgroundColor
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return uiConfig.statusBarStyle
    }

    fileprivate func onboardingCoordinator(uiConfig: ATCUIGenericConfigurationProtocol) -> ATCOnboardingCoordinatorProtocol {
        let landingViewModel = ATCLandingScreenViewModel(imageIcon: "chat-bubble-filled-icon",
                                                         title: "Welcome to Instachatty".localizedCore,
                                                         subtitle: "Stay in touch with your best friends.".localizedCore,
                                                         loginString: "Log In".localizedCore,
                                                         signUpString: "Sign Up".localizedCore)
        
        let phoneLoginViewModel = ATCPhoneLoginScreenViewModel(contactPointField: "E-mail".localizedCore,
                                                               passwordField: "Password".localizedCore,
                                                               title: "Sign In".localizedCore,
                                                               loginString: "Log In".localizedCore,
                                                               sendCodeString: "Send Code".localizedCore,
                                                               submitCodeString: "Submit Code".localizedCore,
                                                               facebookString: "Facebook Login".localizedCore,
                                                               phoneNumberString: "Phone number".localizedCore,
                                                               phoneNumberLoginString: "Login with phone number".localizedCore,
                                                               emailLoginString: "Sign in with E-mail".localizedCore,
                                                               separatorString: "OR".localizedCore,
                                                               contactPoint: .email,
                                                               phoneCodeString: kPhoneVerificationConfig.phoneCode,
                                                               forgotPasswordString: "Forgot Password?".localizedCore)

        let loginViewModel = ATCLoginScreenViewModel(contactPointField: "E-mail or phone number".localizedCore,
                                                     passwordField: "Password".localizedCore,
                                                     title: "Sign In".localizedCore,
                                                     loginString: "Log In".localizedCore,
                                                     facebookString: "Facebook Login".localizedCore,
                                                     separatorString: "OR".localizedCore,
                                                     forgotPasswordString: "Forgot Password?".localizedCore)

        let signUpViewModel = ATCSignUpScreenViewModel(nameField: "Full Name".localizedCore,
                                                       phoneField: "Phone Number".localizedCore,
                                                       emailField: "E-mail Address".localizedCore,
                                                       passwordField: "Password".localizedCore,
                                                       title: "Create new account".localizedCore,
                                                       signUpString: "Sign Up".localizedCore)
        
        let phoneSignUpViewModel = ATCPhoneSignUpScreenViewModel(firstNameField: "First Name".localizedCore,
                                                                 lastNameField: "Last Name".localizedCore,
                                                                 phoneField: "Phone Number".localizedCore,
                                                                 emailField: "E-mail Address".localizedCore,
                                                                 passwordField: "Password".localizedCore,
                                                                 title: "Create new account".localizedCore,
                                                                 signUpString: "Sign Up".localizedCore,
                                                                 separatorString: "OR".localizedCore,
                                                                 contactPoint: .email,
                                                                 phoneNumberString: "Phone number".localizedCore,
                                                                 phoneNumberSignUpString: "Sign up with phone number".localizedCore,
                                                                 emailSignUpString: "Sign up with E-mail".localizedCore,
                                                                 sendCodeString: "Send Code".localizedCore,
                                                                 phoneCodeString: kPhoneVerificationConfig.phoneCode,
                                                                 submitCodeString: "Submit Code".localizedCore)

        let resetPasswordViewModel = ATCResetPasswordScreenViewModel(title: "Reset Password".localizedCore,
                                                                     emailField: "E-mail Address".localizedCore,
                                                                     resetPasswordString: "Reset My Password".localizedCore)
        
        let userManager: ATCSocialUserManagerProtocol? = serverConfig.isFirebaseAuthEnabled ? ATCSocialFirebaseUserManager() : nil

        return ATCClassicOnboardingCoordinator(landingViewModel: landingViewModel,
                                               loginViewModel: loginViewModel,
                                               phoneLoginViewModel: phoneLoginViewModel,
                                               signUpViewModel: signUpViewModel,
                                               phoneSignUpViewModel: phoneSignUpViewModel,
                                               resetPasswordViewModel: resetPasswordViewModel,
                                               uiConfig: ChatOnboardingUIConfig(config: uiConfig),
                                               serverConfig: serverConfig,
                                               userManager: userManager)
    }

    fileprivate func walkthroughVC(uiConfig: ATCUIGenericConfigurationProtocol) -> ATCWalkthroughViewController {
        let viewControllers = ATCChatMockStore.walkthroughs.map { ATCClassicWalkthroughViewController(model: $0, uiConfig: uiConfig, nibName: "ATCClassicWalkthroughViewController", bundle: nil) }
        return ATCWalkthroughViewController(nibName: "ATCWalkthroughViewController",
                                            bundle: nil,
                                            viewControllers: viewControllers,
                                            uiConfig: uiConfig)
    }

    fileprivate func newMessageButton() -> UIButton {
        let newMessageButton = UIButton()
        newMessageButton.configure(icon: UIImage.localImage("inscription-icon", template: true), color: self.uiConfig.mainTextColor)
        newMessageButton.snp.makeConstraints({ (maker) in
            maker.width.equalTo(40.0)
            maker.height.equalTo(40.0)
        })
        newMessageButton.backgroundColor = UIColor.darkModeColor(hexString: "#f5f5f5")
        newMessageButton.layer.cornerRadius = 40.0/2
        newMessageButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10);
        newMessageButton.addTarget(self, action: #selector(didTapNewMessageButton), for: .touchUpInside)
        return newMessageButton
    }

    @objc fileprivate func didTapNewMessageButton() {
        guard let viewer = viewer else { return }
        let vc = ATCChatGroupCreationViewController(uiConfig: uiConfig,
                                                    selectionBlock: nil,
                                                    viewer: viewer,
                                                    chatServiceConfig: chatServiceConfig,
                                                    reportingManager: reportingManager)
        vc.title = "Choose People"
        homeVC.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ChatHostViewController: ATCHostViewControllerDelegate {
    func hostViewController(_ hostViewController: ATCHostViewController, didLogin user: ATCUser) {
        self.viewer = user
        self.homeVC.update(user: user)
        self.contactVC.update(user: user)
        self.profileVC.user = user
    }
    func hostViewController(_ hostViewController: ATCHostViewController, didSync user: ATCUser) {
        self.viewer = user
        self.homeVC.update(user: user)
        self.contactVC.update(user: user)
        self.profileVC.user = user

        if chatServiceConfig.showOnlineStatus || chatServiceConfig.showLastSeen {
            onlinePresenceTracker = ATCOnlinePresenceTracker(viewer: self.viewer, profileManager: self.profileManager)
            onlinePresenceTracker?.startTracking()
        }
    }
}

class ChatOnboardingUIConfig: ATCOnboardingConfigurationProtocol {
    var otpTextFieldBackgroundColor: UIColor
    var otpTextFieldBorderColor: UIColor
    var backgroundColor: UIColor
    var titleColor: UIColor
    var titleFont: UIFont
    var logoTintColor: UIColor?

    var subtitleColor: UIColor
    var subtitleFont: UIFont

    var loginButtonFont: UIFont
    var loginButtonBackgroundColor: UIColor
    var loginButtonTextColor: UIColor

    var signUpButtonFont: UIFont
    var signUpButtonBackgroundColor: UIColor
    var signUpButtonTextColor: UIColor
    var signUpButtonBorderColor: UIColor

    var separatorFont: UIFont
    var separatorColor: UIColor

    var textFieldColor: UIColor
    var textFieldFont: UIFont
    var textFieldBorderColor: UIColor
    var textFieldBackgroundColor: UIColor

    var signUpTextFieldFont: UIFont
    var signUpScreenButtonFont: UIFont

    init(config: ATCUIGenericConfigurationProtocol) {
        backgroundColor = config.mainThemeBackgroundColor
        titleColor = config.mainThemeForegroundColor
        titleFont = config.boldSuperLargeFont
        logoTintColor = config.mainThemeForegroundColor
        subtitleFont = config.regularLargeFont
        subtitleColor = config.mainTextColor
        loginButtonFont = config.boldLargeFont
        loginButtonBackgroundColor = config.mainThemeForegroundColor
        loginButtonTextColor = config.mainThemeBackgroundColor

        signUpButtonFont = config.boldLargeFont
        signUpButtonBackgroundColor = config.mainThemeBackgroundColor
        signUpButtonTextColor = UIColor(hexString: "#414665")
        signUpButtonBorderColor = UIColor(hexString: "#B0B3C6")
        separatorColor = config.mainTextColor
        separatorFont = config.mediumBoldFont

        textFieldColor = UIColor(hexString: "#B0B3C6")
        textFieldFont = config.regularLargeFont
        textFieldBorderColor = UIColor(hexString: "#B0B3C6")
        textFieldBackgroundColor = config.mainThemeBackgroundColor

        signUpTextFieldFont = config.regularMediumFont
        signUpScreenButtonFont = config.mediumBoldFont
        
        otpTextFieldBackgroundColor = UIColor.white
        otpTextFieldBorderColor = UIColor(hexString: "#B0B3C6")
    }
}
