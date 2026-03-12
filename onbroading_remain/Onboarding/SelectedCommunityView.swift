//
//  SelectedCommunityView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 8: Selected Community
struct SelectedCommunityView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            BlueberriesBackground()

            VStack(spacing: 20) {
                Spacer()
                Text("WELCOME TO THE")
                    .font(.custom("Jost-Black", size: 25))
                    .foregroundColor(.white)

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 365, height: 270)
                    .overlay(
                        VStack(spacing: 12) {
                            Image("Blueberry Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                            Text("BLUEBERRY\nCOMMUNITY")
                                .font(.custom("Jost-Black", size: 50))
                                .foregroundColor(.ilyBlue)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.8)
                                .lineSpacing(-4)
                        }
                    )
                Spacer()

                Button {
                    path.append(AppRoute.customizeProfile)
                } label: {
                    Text("Continue")
                        .font(.custom("Inter18pt-Regular", size: 17))
                        .foregroundColor(.ilyBlue)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.bottom, 120)
            }
        }
        .navigationBarHidden(true)
    }
}
