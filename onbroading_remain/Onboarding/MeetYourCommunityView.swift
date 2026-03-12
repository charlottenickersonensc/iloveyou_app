//
//  MeetYourCommunityView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 1: Meet Your Community
struct MeetYourCommunityView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            ScatteredFruitsBackground()

            VStack(spacing: 2) {
                Text("MEET")
                    .font(.custom("Jost-Bold", size: 36))
                    .foregroundColor(.black)
                Text("YOUR")
                    .font(.custom("Jost-Bold", size: 36))
                    .foregroundColor(.black)
                Text("COMMUNITY")
                    .font(.custom("Jost-Bold", size: 36))
                    .foregroundColor(.black)
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    path.append(AppRoute.welcomeSignUp)
                }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}
