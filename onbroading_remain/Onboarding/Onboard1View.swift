//
//  Onboard1View.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 12: Onboard 1
struct Onboard1View: View {
    @Binding var path: NavigationPath

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    Color.ilyBlue.frame(height: 55)

                    Image("Profile Page")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.7)
                        .offset(y: 170)
                        .clipped()

                    Color(red: 1.0, green: 0.6, blue: 0.0)
                }

                LinearGradient(
                    colors: [Color.white, Color(red: 1.0, green: 0.85, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.0)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 253)
                .offset(y: -(geo.size.height * 0.3 - 220) / 2)

                VStack(spacing: 14) {
                    Text("Make a profile that's genuine.")
                        .font(.custom("Inter18pt-Regular", size: 20))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button { path.append(AppRoute.onboard2) } label: {
                        Text("Continue")
                            .font(.custom("Inter18pt-Regular", size: 17))
                            .foregroundColor(.ilyOrange)
                            .padding(.horizontal, 48).padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                    PageDots(count: 6, current: 3)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
