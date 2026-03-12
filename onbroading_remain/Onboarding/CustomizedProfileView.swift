//
//  CustomizedProfileView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 9: Customize Profile (Topics)
struct CustomizeProfileView: View {
    @Binding var path: NavigationPath
    @State private var selected: Set<String> = []

    let topics = [
        "Anime & Cosplay", "Art", "Business & Finance", "Education & Career",
        "Fashion & Beauty", "Food & Drinks", "Games", "Health",
        "Humanities & Lit", "Identities & Relationships", "Internet Culture",
        "Movies & TV", "Music", "Memes", "Mature", "Nature & Outdoors",
        "News & Politics", "Places & Travel", "Pop Culture", "Sciences",
        "Spooky", "Sports", "Technology", "Vehicles", "Vulnerable"
    ]

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
                        .padding(.top, 80)
                    Text("YOU")
                        .font(.custom("Jost-Bold", size: 48))
                        .foregroundColor(.white)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What will YOUR\ncommunity be about?")
                            .font(.custom("Inter18pt-Bold", size: 24))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        Text("Choose 3+ topics that interest you")
                            .font(.custom("Inter18pt-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.8))

                        FlowLayout(spacing: 8) {
                            ForEach(topics, id: \.self) { topic in
                                Button {
                                    if selected.contains(topic) { selected.remove(topic) }
                                    else { selected.insert(topic) }
                                } label: {
                                    Text(topic)
                                        .font(.custom("Inter18pt-Medium", size: 14))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: 250)
                                        .background(selected.contains(topic) ? Color.white : Color.clear)
                                        .foregroundColor(selected.contains(topic) ? .ilyBlue : .white)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                PageDots(count: 6, current: 0)
                    .padding(.vertical, 10)

                Button {
                    path.append(AppRoute.customizeProfile2)
                } label: {
                    Text("Continue")
                        .font(.custom("Inter18pt-Regular", size: 17))
                        .foregroundColor(.ilyBlue)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .disabled(selected.count < 3)
                .opacity(selected.count < 3 ? 0.5 : 1.0)
                .padding(.bottom, 120)
            }
        }
        .navigationBarHidden(true)
    }
}
