//
//  ContentView.swift
//  welcome+intro_page
//

import SwiftUI

// MARK: - Root
struct RootView: View {
    @State private var pageIndex: Int = 0

    var body: some View {
        TabView(selection: $pageIndex) {
            ContentView()
                .tag(0)

            IntroView()
                .tag(1)

            CommunityWordView()
                .tag(2)

            InteractBlueView()
                .tag(3)

            ShareAboutYouView()
                .tag(4)

            FriendsPinkView()
                .tag(5)

            EventsGreenView()
                .tag(6)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
    }
}

// MARK: - Screen 0: ContentView
struct ContentView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    @State private var fruitsOffset: CGFloat = -600
    @State private var fruitsOpacity: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let xScale = screen.width / designW
            let yScale = screen.height / designH
            let scale = min(xScale, yScale)

            ZStack {
                Color.white
                    .ignoresSafeArea()

                Text("iloveyou")
                    .font(.custom("DaysOne-Regular", size: 32))
                    .foregroundStyle(.black)
                    .position(x: screen.width / 2, y: 280 * yScale)

                Image("Fruits")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 1850 * xScale)
                    .offset(x: -700 * xScale, y: (420 * yScale) + fruitsOffset)
                    .opacity(fruitsOpacity)
                    .onAppear {
                        fruitsOffset = -600
                        fruitsOpacity = 0
                        withAnimation(.easeOut(duration: 1.5)) {
                            fruitsOffset = 0
                            fruitsOpacity = 1
                        }
                    }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Screen 1: IntroView
struct IntroView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let xScale = screen.width / designW
            let yScale = screen.height / designH
            let scale = min(xScale, yScale)

            ZStack {
                Color.white
                    .ignoresSafeArea()

                Text("What is iloveyou?")
                    .font(.custom("Jost-ExtraBold", size: 28 * scale))
                    .foregroundStyle(.black)
                    .position(x: screen.width / 2, y: 160)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260 * scale)
                    .position(x: screen.width / 2, y: 420 * yScale)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Screen 2: COMMUNITY
struct CommunityWordView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    private let joinLeft: CGFloat = 33
    private let joinTop: CGFloat = 136
    private let joinW: CGFloat = 140
    private let joinH: CGFloat = 63

    private struct LetterSpec: Identifiable {
        let id = UUID()
        let char: String
        let left: CGFloat
        let top: CGFloat
        let w: CGFloat
        let h: CGFloat
        let delay: Double
        let dx: CGFloat
        let dy: CGFloat
    }

    private let letters: [LetterSpec] = [
        .init(char: "C", left: 19,  top: 265, w: 66, h: 83, delay: 0.00, dx: 0, dy: -4),
        .init(char: "O", left: 91,  top: 296, w: 66, h: 83, delay: 0.05, dx: 0, dy: -2),
        .init(char: "M", left: 173, top: 282, w: 66, h: 83, delay: 0.10, dx: 0, dy: -2),
        .init(char: "M", left: 277, top: 296, w: 66, h: 83, delay: 0.15, dx: 0, dy: -2),
        .init(char: "U", left: 19,  top: 395, w: 66, h: 83, delay: 0.20, dx: 0, dy: -2),
        .init(char: "N", left: 103, top: 395, w: 66, h: 83, delay: 0.25, dx: 0, dy: -2),
        .init(char: "I", left: 168, top: 432, w: 66, h: 83, delay: 0.30, dx: 0, dy: -6),
        .init(char: "T", left: 224, top: 395, w: 66, h: 83, delay: 0.35, dx: 0, dy: -2),
        .init(char: "Y", left: 308, top: 426, w: 66, h: 83, delay: 0.40, dx: 0, dy: -4)
    ]

    @State private var showLetters = false

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let scale = min(screen.width / designW, screen.height / designH)
            let fittedW = designW * scale
            let fittedH = designH * scale
            let offsetX = (screen.width - fittedW) / 2
            let offsetY = (screen.height - fittedH) / 2

            ZStack {
                Color.orange.ignoresSafeArea()

                joinAText(scale: scale, offsetX: offsetX, offsetY: offsetY)

                ForEach(letters) { letter in
                    letterView(letter, scale: scale, offsetX: offsetX, offsetY: offsetY)
                }
            }
            .onAppear {
                showLetters = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showLetters = true
                }
            }
        }
        .ignoresSafeArea()
    }

    private func joinAText(scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        let x = offsetX + (joinLeft + joinW / 2) * scale
        let y = offsetY + (joinTop + joinH / 2) * scale
        return Text("join a")
            .font(.custom("Jost-Medium", size: 48 * scale))
            .foregroundStyle(.black)
            .fixedSize()
            .position(x: x, y: y)
    }

    private func letterView(_ letter: LetterSpec, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        let x = offsetX + (letter.left + letter.w / 2 + letter.dx) * scale
        let y = offsetY + (letter.top + letter.h / 2 + letter.dy) * scale
        return Text(letter.char)
            .font(.custom("Jost-ExtraBold", size: 90))
            .foregroundStyle(.white)
            .fixedSize()
            .position(x: x, y: y)
            .offset(y: showLetters ? 0 : 28 * scale)
            .scaleEffect(showLetters ? 1.0 : 0.92)
            .opacity(showLetters ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.82).delay(letter.delay),
                value: showLetters
            )
    }
}

// MARK: - Screen 3: INTERACT
struct InteractBlueView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    private struct LetterSpec: Identifiable {
        let id = UUID()
        let char: String
        let x: CGFloat
        let y: CGFloat
    }

    private let letters: [LetterSpec] = [
        .init(char: "I", x: 55,  y: 273),
        .init(char: "N", x: 112, y: 282),
        .init(char: "T", x: 198, y: 268),
        .init(char: "E", x: 264, y: 282),
        .init(char: "R", x: 46,  y: 382),
        .init(char: "A", x: 128, y: 378),
        .init(char: "C", x: 204, y: 368),
        .init(char: "T", x: 291, y: 392)
    ]

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let xScale = screen.width / designW
            let yScale = screen.height / designH

            ZStack(alignment: .topLeading) {
                Color(red: 0.10, green: 0.49, blue: 0.87)
                    .ignoresSafeArea()

                // Taller orange block to clear camera
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 393 * xScale, height: 110 * yScale)

                // "join a COMMUNITY" on one line, pushed below camera
                HStack(spacing: 6 * min(xScale, yScale)) {
                    Text("join a")
                        .font(.custom("Jost-Medium", size: 30 * min(xScale, yScale)))
                        .foregroundStyle(.white)
                    Text("COMMUNITY")
                        .font(.custom("Jost-ExtraBold", size: 30 * min(xScale, yScale)))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 60 * yScale)

                ForEach(letters) { letter in
                    Text(letter.char)
                        .font(.custom("Jost-ExtraBold", size: 90))
                        .foregroundStyle(.white)
                        .fixedSize()
                        .offset(x: letter.x * xScale, y: letter.y * yScale)
                }

                Text("with group")
                    .font(.custom("Jost-Medium", size: 48 * min(xScale, yScale)))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .offset(x: 37 * xScale, y: 516 * yScale)

                Text("members")
                    .font(.custom("Jost-Medium", size: 48 * min(xScale, yScale)))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .offset(x: 37 * xScale, y: 566 * yScale)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Screen 4: ShareAboutYouView
struct ShareAboutYouView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    private struct LetterSpec: Identifiable {
        let id = UUID()
        let char: String
        let x: CGFloat
        let y: CGFloat
        let rotation: CGFloat
    }

    private let letters: [LetterSpec] = [
        .init(char: "Y", x: 58,    y: 468,    rotation: 0),
        .init(char: "O", x: 118,   y: 482,    rotation: 0),
        .init(char: "U", x: 198,   y: 463,    rotation: 0),
        .init(char: "!", x: 278,   y: 470.63, rotation: 13.02)
    ]

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let xScale = screen.width / designW
            let yScale = screen.height / designH
            let scale = min(xScale, yScale)

            ZStack(alignment: .topLeading) {
                Color(red: 0.996, green: 0.941, blue: 0.0)
                    .ignoresSafeArea()

                // Taller orange block to clear camera
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 393 * xScale, height: 110 * yScale)

                Rectangle()
                    .fill(Color(red: 0.10, green: 0.49, blue: 0.87))
                    .frame(width: 393 * xScale, height: 83 * yScale)
                    .offset(x: 0, y: 110 * yScale)

                // "join a COMMUNITY" on one line, pushed below camera
                HStack(spacing: 6 * scale) {
                    Text("join a")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("COMMUNITY")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 60 * yScale)

                HStack(spacing: 6 * scale) {
                    Text("INTERACT")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("with group")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 118 * yScale)

                Text("members")
                    .font(.custom("Jost-Medium", size: 30 * scale))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .offset(x: 14 * xScale, y: 148 * yScale)

                Text("share")
                    .font(.custom("Jost-Medium", size: 48 * scale))
                    .foregroundStyle(.black)
                    .fixedSize()
                    .offset(x: 133 * xScale, y: 365 * yScale)

                Text("about")
                    .font(.custom("Jost-Medium", size: 48 * scale))
                    .foregroundStyle(.black)
                    .fixedSize()
                    .offset(x: 133 * xScale, y: 415 * yScale)

                ForEach(letters) { letter in
                    Text(letter.char)
                        .font(.custom("Jost-ExtraBold", size: 90))
                        .foregroundStyle(.black)
                        .fixedSize()
                        .rotationEffect(.degrees(letter.rotation))
                        .offset(x: letter.x * xScale, y: letter.y * yScale)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Screen 5: FriendsPinkView
struct FriendsPinkView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    private struct LetterSpec: Identifiable {
        let id = UUID()
        let char: String
        let x: CGFloat
        let y: CGFloat
        let rotation: CGFloat
    }

    private let letters: [LetterSpec] = [
        .init(char: "F", x: 60,  y: 430, rotation: 0),
        .init(char: "R", x: 135, y: 428, rotation: 0),
        .init(char: "I", x: 226, y: 430, rotation: 0),
        .init(char: "E", x: 268, y: 428, rotation: 0),
        .init(char: "N", x: 60,  y: 530, rotation: 0),
        .init(char: "D", x: 150, y: 518, rotation: 0),
        .init(char: "S", x: 248, y: 530, rotation: 0)
    ]

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let xScale = screen.width / designW
            let yScale = screen.height / designH
            let scale = min(xScale, yScale)

            ZStack(alignment: .topLeading) {
                Color(red: 1.0, green: 0.0, blue: 0.533)
                    .ignoresSafeArea()

                // Taller orange block to clear camera
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 393 * xScale, height: 110 * yScale)

                Rectangle()
                    .fill(Color(red: 0.10, green: 0.49, blue: 0.87))
                    .frame(width: 393 * xScale, height: 83 * yScale)
                    .offset(x: 0, y: 110 * yScale)

                Rectangle()
                    .fill(Color(red: 0.996, green: 0.941, blue: 0.0))
                    .frame(width: 393 * xScale, height: 55 * yScale)
                    .offset(x: 0, y: 193 * yScale)

                // "join a COMMUNITY" on one line, pushed below camera
                HStack(spacing: 6 * scale) {
                    Text("join a")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("COMMUNITY")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 60 * yScale)

                HStack(spacing: 6 * scale) {
                    Text("INTERACT")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("with group")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 118 * yScale)

                Text("members")
                    .font(.custom("Jost-Medium", size: 30 * scale))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .offset(x: 14 * xScale, y: 148 * yScale)

                HStack(spacing: 0) {
                    Text("share about ")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.black)
                    Text("YOU!")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.black)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 199 * yScale)

                Text("message")
                    .font(.custom("Jost-Medium", size: 48 * scale))
                    .foregroundStyle(.black)
                    .fixedSize()
                    .offset(x: 90 * xScale, y: 360 * yScale)

                ForEach(letters) { letter in
                    Text(letter.char)
                        .font(.custom("Jost-ExtraBold", size: 90))
                        .foregroundStyle(.white)
                        .fixedSize()
                        .rotationEffect(.degrees(letter.rotation))
                        .offset(x: letter.x * xScale, y: letter.y * yScale)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Screen 6: EventsGreenView
struct EventsGreenView: View {

    private let designW: CGFloat = 393
    private let designH: CGFloat = 852

    private struct LetterSpec: Identifiable {
        let id = UUID()
        let char: String
        let x: CGFloat
        let y: CGFloat
        let rotation: CGFloat
    }

    private let letters: [LetterSpec] = [
        .init(char: "E", x: 14,  y: 490, rotation: 0),
        .init(char: "V", x: 70,  y: 518, rotation: 0),
        .init(char: "E", x: 140, y: 500, rotation: 0),
        .init(char: "N", x: 210, y: 490, rotation: 0),
        .init(char: "T", x: 290, y: 480, rotation: 0),
        .init(char: "S", x: 325, y: 510, rotation: 0)
    ]

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let xScale = screen.width / designW
            let yScale = screen.height / designH
            let scale = min(xScale, yScale)

            ZStack(alignment: .topLeading) {
                Color(red: 0.169, green: 0.776, blue: 0.0)
                    .ignoresSafeArea()

                // Taller orange block to clear camera
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 393 * xScale, height: 110 * yScale)

                Rectangle()
                    .fill(Color(red: 0.10, green: 0.49, blue: 0.87))
                    .frame(width: 393 * xScale, height: 83 * yScale)
                    .offset(x: 0, y: 110 * yScale)

                Rectangle()
                    .fill(Color(red: 0.996, green: 0.941, blue: 0.0))
                    .frame(width: 393 * xScale, height: 55 * yScale)
                    .offset(x: 0, y: 193 * yScale)

                Rectangle()
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.533))
                    .frame(width: 393 * xScale, height: 55 * yScale)
                    .offset(x: 0, y: 248 * yScale)

                // "join a COMMUNITY" on one line, pushed below camera
                HStack(spacing: 6 * scale) {
                    Text("join a")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("COMMUNITY")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 60 * yScale)

                HStack(spacing: 6 * scale) {
                    Text("INTERACT")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("with group")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 118 * yScale)

                Text("members")
                    .font(.custom("Jost-Medium", size: 30 * scale))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .offset(x: 14 * xScale, y: 148 * yScale)

                HStack(spacing: 0) {
                    Text("share about ")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.black)
                    Text("YOU!")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.black)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 199 * yScale)

                HStack(spacing: 4 * scale) {
                    Text("message")
                        .font(.custom("Jost-Medium", size: 30 * scale))
                        .foregroundStyle(.white)
                    Text("FRIENDS")
                        .font(.custom("Jost-ExtraBold", size: 30 * scale))
                        .foregroundStyle(.white)
                }
                .fixedSize()
                .offset(x: 14 * xScale, y: 254 * yScale)

                Text("create")
                    .font(.custom("Jost-Medium", size: 48 * scale))
                    .foregroundStyle(.black)
                    .fixedSize()
                    .offset(x: 118 * xScale, y: 360 * yScale)

                Text("and join")
                    .font(.custom("Jost-Medium", size: 48 * scale))
                    .foregroundStyle(.black)
                    .fixedSize()
                    .offset(x: 100 * xScale, y: 410 * yScale)

                ForEach(letters) { letter in
                    Text(letter.char)
                        .font(.custom("Jost-ExtraBold", size: 98 * scale))
                        .foregroundStyle(.white)
                        .fixedSize()
                        .rotationEffect(.degrees(letter.rotation))
                        .offset(x: letter.x * xScale, y: letter.y * yScale)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    RootView()
}
