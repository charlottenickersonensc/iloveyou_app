//
//  JoinCommunityView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 7: Join Community (Spin Wheel)
struct JoinCommunityView: View {
    @Binding var path: NavigationPath
    @State private var rotation: Double = 0
    @State private var showFruitOverlay = false
    @State private var fruitY: CGFloat = 0
    @State private var navigated = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    Spacer()
                    Triangle()
                        .fill(Color.black)
                        .frame(width: 30, height: 90)
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350)
                        .rotationEffect(.degrees(rotation))
                        .gesture(
                            DragGesture()
                                .onChanged { val in
                                    let delta = Double(val.translation.width - val.translation.height) * 0.4
                                    rotation += delta / 10
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 1.2)) {
                                        rotation += Double.random(in: 360...720)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                        fruitY = -geo.size.height
                                        showFruitOverlay = true
                                        withAnimation(.easeOut(duration: 1.2)) {
                                            fruitY = geo.size.height / 2
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            if !navigated {
                                                navigated = true
                                                path.append(AppRoute.selectedCommunity)
                                            }
                                        }
                                    }
                                }
                        )
                    Spacer()
                        .frame(height: 260)
                }

                if showFruitOverlay {
                    Image("Falling Blueberry - animate")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .position(x: geo.size.width / 2, y: fruitY)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

// MARK: - Triangle Shape (used only in JoinCommunityView)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
