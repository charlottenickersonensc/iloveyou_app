//
//  CustomizedProfileView2.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 10: Customize Profile 2
struct CustomizeProfile2View: View {
    @Binding var path: NavigationPath
    @State private var hometown = ""
    @State private var primaryLocation = ""
    @State private var school = ""

    var body: some View {
        ZStack {
            Color.ilyBlue.ignoresSafeArea()
            Image("Background Bluebs 1")
                .resizable()
                .scaledToFill()
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("TELL THE BLUEBERRIES ABOUT")
                        .font(.custom("Inter18pt-Medium", size: 16))
                        .foregroundColor(.white)
                        .padding(.top, 140)
                    Text("YOU")
                        .font(.custom("Jost-Bold", size: 48))
                        .foregroundColor(.white)
                }

                VStack(spacing: 20) {
                    profileField("Hometown", text: $hometown)
                    profileField("Primary Location*", text: $primaryLocation)
                    profileField("School", text: $school)
                }
                .padding(.horizontal, 24)
                .padding(.top, 100)

                Spacer()

                PageDots(count: 6, current: 1)
                    .padding(.vertical, 12)

                Button {
                    path.append(AppRoute.customizePFP)
                } label: {
                    Text("Continue")
                        .font(.custom("Inter18pt-Regular", size: 17))
                        .foregroundColor(.ilyBlue)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.bottom, 120)
            }
        }
        .navigationBarHidden(true)
    }

    private func profileField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.custom("Inter18pt-Bold", size: 18))
                .foregroundColor(.white)
            TextField("type here", text: text)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                .foregroundColor(.black)
                .tint(.ilyBlue)
        }
    }
}
