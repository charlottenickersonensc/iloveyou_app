//
//  CustomizePFPView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 11: Customize Profile Picture
struct CustomizePFPView: View {
    @Binding var path: NavigationPath
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var confirmed = false

    var body: some View {
        ZStack {
            Color.ilyBlue.ignoresSafeArea()
            Image("Background Bluebs 1")
                .resizable()
                .scaledToFill()
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Select your\nProfile Picture")
                    .font(.custom("Jost-Bold", size: 40))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 160)

                Spacer()

                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .padding(.bottom, 40)
                } else {
                    Button { showImagePicker = true } label: {
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color.white)
                            .frame(width: 220, height: 100)
                            .overlay(
                                Text("select image from\ncamera gallery")
                                    .font(.custom("Inter18pt-Regular", size: 20))
                                    .foregroundColor(.ilyBlue)
                                    .multilineTextAlignment(.center)
                            )
                    }
                    .padding(.bottom, 100)
                }

                Spacer()

                PageDots(count: 6, current: 2)
                    .padding(.bottom, 16)

                if selectedImage != nil && !confirmed {
                    HStack(spacing: 20) {
                        Button { selectedImage = nil } label: {
                            Text("Back")
                                .font(.custom("Inter18pt-Regular", size: 17))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32).padding(.vertical, 12)
                                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white))
                        }
                        Button { confirmed = true } label: {
                            Text("Continue")
                                .font(.custom("Inter18pt-Regular", size: 17))
                                .foregroundColor(.ilyBlue)
                                .padding(.horizontal, 32).padding(.vertical, 12)
                                .background(Color.white).cornerRadius(30)
                        }
                    }
                    .padding(.bottom, 120)
                } else if confirmed {
                    Button { path.append(AppRoute.onboard1) } label: {
                        Text("Continue")
                            .font(.custom("Inter18pt-Regular", size: 17))
                            .foregroundColor(.ilyBlue)
                            .padding(.horizontal, 48).padding(.vertical, 12)
                            .background(Color.white).cornerRadius(30)
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $selectedImage) }
        .navigationBarHidden(true)
    }
}
