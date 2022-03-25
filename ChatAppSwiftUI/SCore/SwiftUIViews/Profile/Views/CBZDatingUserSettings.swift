//
//  CBZUserSettings.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 15/05/21.
//

import SwiftUI

struct CBZDatingUserSettings: View {
    @ObservedObject var viewModel: CBZDatingProfileViewModel
    @State private var updateTime: Date = Date()
    var appConfig: CBZDatingInAppConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(viewModel: CBZDatingProfileViewModel, appConfig: CBZDatingInAppConfigurationProtocol) {
        self.viewModel = viewModel
        self.appConfig = appConfig
    }
    
    var body: some View {
        Form {
            ForEach(0..<viewModel.sections.count) { i in
                Section(header: Text(viewModel.sections[i].title)) {
                    ForEach(0..<viewModel.sections[i].options.count) { j in
                        if viewModel.sections[i].options[j].isBoolType {
                            CBZSettingsToggleView(title: viewModel.sections[i].options[j].title,
                                                  isOn: $viewModel.sections[i].options[j].isToggleOn)
                        } else {
                            CBZSettingsActionView(title: viewModel.sections[i].options[j].title,
                                                  optionTitle: viewModel.sections[i].options[j].actionTitle,
                                                  options: viewModel.sections[i].options[j].options,
                                                  selectedValue: $viewModel.sections[i].options[j].settingValue)
                        }
                    }
                }
            }
            Section(header: Text("")) {
                Button(action: {
                    var settingsJson: [String: Any] = [:]
                    var isPushNotificationsEnabled = false
                    for section in viewModel.sections {
                        for option in section.options {
                            if option.isBoolType {
                                settingsJson[option.key] = option.isToggleOn
                            } else {
                                settingsJson[option.key] = option.settingValue
                            }
                            if option.key == "push_notifications_enabled" {
                                isPushNotificationsEnabled = option.isToggleOn
                            }
                        }
                    }
                    self.viewModel.updateSettings(userSettingsJSON: ["settings": settingsJson],
                                                  isPushNotificationsEnabled: isPushNotificationsEnabled) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Save".localizedSettings)
                        Spacer()
                    }
                }
            }
        }
        .id(updateTime)
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showLoader ? 1 : 0)
        )
        .navigationBarTitle("User Settings".localizedChat)
        .onAppear {
            self.viewModel.sections = appConfig.settingsSections

            for section in viewModel.sections {
                for option in section.options {
                    if option.isBoolType {
                        option.isToggleOn = viewModel.loggedInUser?.settings[option.key] as? Bool ?? false
                    } else {
                        option.settingValue = viewModel.loggedInUser?.settings[option.key] as? String ?? ""
                    }
                }
            }
            
            updateTime = Date()
        }
    }
    
    func generateActionSheet(options: [String], selectedOption: Binding<String>, title: String) -> ActionSheet {
        let buttons = options.enumerated().map { i, option in
            Alert.Button.default(Text(option), action: { selectedOption.wrappedValue = option } )
        }
        return ActionSheet(title: Text(title),
                           buttons: buttons + [Alert.Button.cancel()])
    }
    
    var isPushNotificationEnabled: Bool {
        var isRegisteredForRemoteNotifications: Bool = false
        
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus  {
            case .authorized:
                isRegisteredForRemoteNotifications = true
            default:
                isRegisteredForRemoteNotifications = false
            }
        })
        
      return isRegisteredForRemoteNotifications
    }
}

struct CBZSettingsToggleView: View {
    
    var title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Toggle(isOn: $isOn) {
                Text(title)
            }
        }
    }
}

struct CBZSettingsActionView: View {
    
    var title: String
    var optionTitle: String
    var options: [String]
    @Binding var selectedValue: String
    @State private var showAction = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: {
                showAction = true
            }) {
                Text(selectedValue)
                    .foregroundColor(Color(UIColor.black.darkModed))
            }
            .actionSheet(isPresented: $showAction) {
                self.generateActionSheet(options: options, selectedOption: $selectedValue, title: title)
            }
        }
    }
    
    func generateActionSheet(options: [String], selectedOption: Binding<String>, title: String) -> ActionSheet {
        let buttons = options.enumerated().map { i, option in
            Alert.Button.default(Text(option), action: { selectedOption.wrappedValue = option } )
        }
        return ActionSheet(title: Text(title),
                           buttons: buttons + [Alert.Button.cancel()])
    }
}

struct CBZSettingSection: Identifiable {
    var id = UUID()
    var title: String
    var options: [CBZSettingOptions]
}

class CBZSettingOptions: ObservableObject {
    var id = UUID()
    var title: String
    var actionTitle: String = ""
    var key: String
    var isBoolType: Bool
    var options: [String] = []
    @Published var isToggleOn: Bool = false
    @Published var settingValue: String = ""
    
    init(title: String, actionTitle: String = "", key: String, isBoolType: Bool, options: [String] = []) {
        self.title = title
        self.actionTitle = actionTitle
        self.key = key
        self.isBoolType = isBoolType
        self.options = options
    }
}
