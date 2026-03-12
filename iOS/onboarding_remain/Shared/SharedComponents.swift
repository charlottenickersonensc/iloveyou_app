//
//  SharedComponents.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Color Theme
extension Color {
    static let ilyOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let ilyBlue   = Color(red: 0.255, green: 0.392, blue: 0.902)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Underline Text Field Style
extension View {
    func underlineStyle() -> some View {
        self.overlay(
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.5)).padding(.top, 32),
            alignment: .bottom
        )
        .padding(.bottom, 4)
    }
}

// MARK: - Reusable: Fruits Header
struct FruitsHeader: View {
    var body: some View {
        GeometryReader { geo in
            Image("Background Images 2")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width * 1.4, height: 200)
                .offset(x: -geo.size.width * 0.2, y: -80)
                .clipped()
        }
        .frame(height: 160)
        .clipped()
    }
}

// MARK: - Reusable: Blueberry Background
struct BlueberriesBackground: View {
    var body: some View {
        ZStack {
            Color.ilyBlue.ignoresSafeArea()
            Image("Background Bluebs 1")
                .resizable()
                .scaledToFill()
                .opacity(1)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Reusable: Scattered Fruits Background
struct ScatteredFruitsBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color.white.ignoresSafeArea()
                Image("Background Images 1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w * 1.2, height: h * 1.2)
                    .clipped()
                    .offset(x: -35, y: -50)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Page Dots Indicator
struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.ilyOrange : Color.gray.opacity(0.4))
                    .frame(width: i == current ? 10 : 7, height: i == current ? 10 : 7)
            }
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var rowX: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > width && rowX > 0 {
                height += rowHeight + spacing
                rowX = 0
                rowHeight = 0
            }
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX = bounds.minX
        var rowY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > bounds.maxX && rowX > bounds.minX {
                rowY += rowHeight + spacing
                rowX = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: .unspecified)
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
