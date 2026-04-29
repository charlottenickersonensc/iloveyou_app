import Foundation

public struct FruitCommunity: Identifiable, Codable, Equatable {
    public let id: String
    public let code: String
    public let name: String
    public let themeColorHex: String
    public let badgeAssetName: String
    public let wheelIndex: Int

    public init(id: String, code: String, name: String, themeColorHex: String, badgeAssetName: String, wheelIndex: Int) {
        self.id = id
        self.code = code
        self.name = name
        self.themeColorHex = themeColorHex
        self.badgeAssetName = badgeAssetName
        self.wheelIndex = wheelIndex
    }
}

public extension FruitCommunity {
    static let sprintOneSeed: [FruitCommunity] = [
        .init(id: "apple", code: "apple", name: "Apple", themeColorHex: "#D94A38", badgeAssetName: "fruit_apple", wheelIndex: 0),
        .init(id: "banana", code: "banana", name: "Banana", themeColorHex: "#F0C84B", badgeAssetName: "fruit_banana", wheelIndex: 1),
        .init(id: "cherry", code: "cherry", name: "Cherry", themeColorHex: "#C72C48", badgeAssetName: "fruit_cherry", wheelIndex: 2),
        .init(id: "grape", code: "grape", name: "Grape", themeColorHex: "#7652A8", badgeAssetName: "fruit_grape", wheelIndex: 3),
        .init(id: "kiwi", code: "kiwi", name: "Kiwi", themeColorHex: "#6E9F3D", badgeAssetName: "fruit_kiwi", wheelIndex: 4),
        .init(id: "lemon", code: "lemon", name: "Lemon", themeColorHex: "#E4CF3B", badgeAssetName: "fruit_lemon", wheelIndex: 5),
        .init(id: "mango", code: "mango", name: "Mango", themeColorHex: "#EE8F2E", badgeAssetName: "fruit_mango", wheelIndex: 6),
        .init(id: "orange", code: "orange", name: "Orange", themeColorHex: "#E97826", badgeAssetName: "fruit_orange", wheelIndex: 7),
        .init(id: "peach", code: "peach", name: "Peach", themeColorHex: "#EF9F88", badgeAssetName: "fruit_peach", wheelIndex: 8),
        .init(id: "pear", code: "pear", name: "Pear", themeColorHex: "#9DBB48", badgeAssetName: "fruit_pear", wheelIndex: 9),
        .init(id: "pineapple", code: "pineapple", name: "Pineapple", themeColorHex: "#D8A329", badgeAssetName: "fruit_pineapple", wheelIndex: 10),
        .init(id: "strawberry", code: "strawberry", name: "Strawberry", themeColorHex: "#D93B52", badgeAssetName: "fruit_strawberry", wheelIndex: 11)
    ]
}
