//
//  TermsAndConditionsView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 5: Terms and Conditions
struct TermsAndConditionsView: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            FruitsHeader()

            VStack(spacing: 16) {
                Text("Before we move on...")
                    .font(.custom("DaysOne-Regular", size: 24))
                    .foregroundColor(.ilyOrange)
                    .padding(.top, 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "F2F3FC"))
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "312A5E"), lineWidth: 1.5)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms and Conditions")
                                .font(.custom("Inter18pt-Bold", size: 20))
                                .foregroundColor(Color(hex: "312A5E"))
                            Text("By using iloveyou, you agree to our terms of service. You must be 13 or older to use this app. You are responsible for all activity on your account.")
                                .font(.custom("Inter18pt-Regular", size: 14))
                                .foregroundColor(.gray)
                            Text("Our Values")
                                .font(.custom("Inter18pt-Bold", size: 20))
                                .foregroundColor(Color(hex: "312A5E"))
                            Text("We believe in kindness, inclusivity, and authentic connection. We do not tolerate harassment, hate speech, or harmful content of any kind.")
                                .font(.custom("Inter18pt-Regular", size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .padding(.horizontal, 24)

                HStack(spacing: 20) {
                    Button {
                        path.removeLast(path.count)
                    } label: {
                        Text("Disagree")
                            .font(.custom("Inter18pt-Regular", size: 17))
                            .foregroundColor(.ilyOrange)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ilyOrange, lineWidth: 1.5))
                    }
                    Button {
                        path.append(AppRoute.beginCommunitySearch)
                    } label: {
                        Text("Agree")
                            .font(.custom("Inter18pt-Regular", size: 17))
                            .foregroundColor(.ilyOrange)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ilyOrange, lineWidth: 1.5))
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }
}
