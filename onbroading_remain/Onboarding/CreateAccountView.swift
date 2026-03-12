//
//  CreateAccountView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 3: Create Account
struct CreateAccountView: View {
    @Binding var path: NavigationPath
    @State private var email = ""
    @State private var phone = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var dateOfBirth = Date()
    @State private var pronouns = ""
    @State private var location = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FruitsHeader()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Create Account")
                        .font(.custom("DaysOne-Regular", size: 24))
                        .foregroundColor(.ilyOrange)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)

                    fieldLabel("Email*")
                    TextField("type here", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .underlineStyle()

                    fieldLabel("Phone Number*")
                    TextField("type here", text: $phone)
                        .keyboardType(.phonePad)
                        .underlineStyle()

                    fieldLabel("First Name*")
                    TextField("type here", text: $firstName)
                        .underlineStyle()

                    fieldLabel("Last Name*")
                    TextField("type here", text: $lastName)
                        .underlineStyle()

                    fieldLabel("Create Password*")
                    SecureField("type here", text: $password)
                        .underlineStyle()

                    Text("Password must:\n• contain 3-20 characters\n• contain 1 unique symbol")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(.top, -8)

                    VStack(alignment: .leading, spacing: 2) {
                        fieldLabel("Date of Birth*")
                        Text("will not be shared publicly")
                            .font(.caption)
                            .foregroundColor(.gray)

                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.ilyOrange)
                    }

                    fieldLabel("Pronouns")
                    TextField("type here", text: $pronouns)
                        .underlineStyle()

                    fieldLabel("Location")
                    TextField("type here", text: $location)
                        .underlineStyle()

                    Button {
                        path.append(AppRoute.verifyAccount(phone))
                    } label: {
                        Text("Create Account")
                            .font(.custom("Inter18pt-Regular", size: 17))
                            .foregroundColor(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 14)
                            .background(Color.ilyOrange)
                            .cornerRadius(30)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Inter18pt-Regular", size: 17))
            .foregroundColor(.black)
    }
}
