import SwiftUI

public struct FruitWheelView: View {
    public let fruits: [FruitCommunity]

    public init(fruits: [FruitCommunity] = FruitCommunity.sprintOneSeed) {
        self.fruits = fruits.sorted { $0.wheelIndex < $1.wheelIndex }
    }

    public var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let sliceAngle = Angle.degrees(360.0 / Double(fruits.count))

            for fruit in fruits {
                let start = Angle.degrees(Double(fruit.wheelIndex) * sliceAngle.degrees)
                let end = Angle.degrees(Double(fruit.wheelIndex + 1) * sliceAngle.degrees)
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                path.closeSubpath()
                context.fill(path, with: .color(Color(hex: fruit.themeColorHex)))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(alignment: .top) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.title2)
                .foregroundStyle(.primary)
                .offset(y: -8)
        }
        .accessibilityLabel("Fruit reveal wheel")
    }
}
