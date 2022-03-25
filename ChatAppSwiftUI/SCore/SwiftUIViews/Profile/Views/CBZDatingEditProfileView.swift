//
//  CBZDatingEditProfileView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 14/05/21.
//

import SwiftUI

struct CBZDatingEditProfileView: View {
    @ObservedObject var viewModel: CBZDatingProfileViewModel
    
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var age: String = ""
    @State var bio: String = ""
    @State var school: String = ""
    @State var email: String = ""
    @State var phoneNumber: String = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(viewModel: CBZDatingProfileViewModel) {
        self.viewModel = viewModel
        _firstName = State(initialValue: viewModel.loggedInUser?.firstName ?? "")
        _lastName = State(initialValue: viewModel.loggedInUser?.lastName ?? "")
        _age = State(initialValue: viewModel.loggedInUser?.age ?? "")
        _bio = State(initialValue: viewModel.loggedInUser?.bio ?? "")
        _school = State(initialValue: viewModel.loggedInUser?.school ?? "")
        _email = State(initialValue: viewModel.loggedInUser?.email ?? "")
        _phoneNumber = State(initialValue: viewModel.loggedInUser?.phoneNumber ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("PUBLIC PROFILE".localizedChat)) {
                HStack {
                    Text("First Name".localizedCore)
                    Spacer()
                    TextField("Your first name".localizedChat, text: $firstName)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Last Name".localizedCore)
                    Spacer()
                    TextField("Your last name".localizedChat, text: $lastName)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Age".localizedCore)
                    Spacer()
                    TextField("Your age".localizedChat, text: $age)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Bio".localizedCore)
                    Spacer()
                    TextField("Say something about you".localizedChat, text: $bio)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("School".localizedCore)
                    Spacer()
                    TextField("School".localizedChat, text: $school)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section(header: Text("PRIVATE DETAILS".localizedChat)) {
                HStack {
                    Text("E-mail Address".localizedCore)
                    Spacer()
                    TextField("Your email address".localizedChat, text: $email)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Phone Number".localizedCore)
                    Spacer()
                    TextField("Your phone number".localizedChat, text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showLoader ? 1 : 0)
        )
        .navigationBarTitle("Edit Profile".localizedCore)
        .navigationBarItems(trailing:
                                Button(action: {
                                    viewModel.update(email: email,
                                                     firstName: firstName,
                                                     lastName: lastName,
                                                     phone: phoneNumber,
                                                     age: age,
                                                     bio: bio,
                                                     school: school) {
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    Text("Done".localizedCore)
                                })
    }
}
