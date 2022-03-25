//
//  CBZContactUsView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 05/06/21.
//

import SwiftUI

struct CBZContactUsView: View {
    var uiConfig: CBZUIConfigurationProtocol

    var body: some View {
        Form {
            Section(header: Text("Contact".localizedFeed)) {
                HStack {
                    Text("Address".localizedFeed)
                        .font(uiConfig.regularFont(size: 15))
                    Spacer()
                    Text("142 Steiner Street, San Francisco, CA, 94115")
                        .font(uiConfig.regularFont(size: 15))
                }
                HStack {
                    Text("E-mail us".localizedFeed)
                        .font(uiConfig.regularFont(size: 15))
                    Spacer()
                    Text("florian@instamobile.io")
                        .font(uiConfig.regularFont(size: 15))
                }
            }
            Section(header: Text("")) {
                Button(action: {
                    guard let number = URL(string: "tel://+16504859694") else { return }
                    UIApplication.shared.open(number)
                }) {
                    HStack {
                        Spacer()
                        Text("Call Us".localizedFeed)
                        Spacer()
                    }
                }
            }
        }.navigationBarTitle("Contact Us".localizedFeed)
    }
}
