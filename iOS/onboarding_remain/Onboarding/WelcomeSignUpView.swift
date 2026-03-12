//
//  WelcomeSignUpView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 2: Welcome / Sign Up
struct WelcomeSignUpView: View {
    @Binding var path: NavigationPath
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            ScatteredFruitsBackground()

            VStack(spacing: 18) {
                Text("Welcome!")
                    .font(.custom("DaysOne-Regular", size: 32))
                    .foregroundColor(.black)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72)

                VStack(spacing: 12) {
                    TextField("username", text: $username)
                        .font(.system(size: 15))
                        .autocapitalization(.none)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        .frame(width: 220)

                    SecureField("password", text: $password)
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        .frame(width: 220)
                }

                Button {
                    // Log In action
                } label: {
                    Text("Log In")
                        .font(.custom("Inter18pt-Regular", size: 17))
                        .foregroundColor(.white)
                        .frame(width: 220)
                        .padding(.vertical, 12)
                        .background(Color.ilyOrange)
                        .cornerRadius(30)
                }

                Text("or")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Button {
                    path.append(AppRoute.createAccount)
                } label: {
                    Text("Sign Up")
                        .font(.custom("Inter18pt-Regular", size: 17))
                        .foregroundColor(.ilyOrange)
                        .frame(width: 220)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.ilyOrange, lineWidth: 1.5)
                        )
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}
