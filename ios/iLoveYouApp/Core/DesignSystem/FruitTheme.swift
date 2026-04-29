import SwiftUI

public struct FruitTheme: Equatable {
    public let fruit: FruitCommunity

    public var color: Color {
        Color(hex: fruit.themeColorHex)
    }

    public init(fruit: FruitCommunity) {
        self.fruit = fruit
    }
}

public extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let red = Double((value >> 16) & 0xff) / 255.0
        let green = Double((value >> 8) & 0xff) / 255.0
        let blue = Double(value & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
