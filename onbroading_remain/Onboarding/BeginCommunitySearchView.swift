//
//  BeginCommunitySearchView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 6: Begin Community Search
struct BeginCommunitySearchView: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Are you ready to find\nyour community?")
                .font(.custom("Jost-Bold", size: 25))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
            Button {
                path.append(AppRoute.joinCommunity)
            } label: {
                Text("Let's go!")
                    .font(.custom("Inter18pt-Regular", size: 17))
                    .foregroundColor(.ilyOrange)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ilyOrange, lineWidth: 1.5))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .navigationBarHidden(true)
    }
}
