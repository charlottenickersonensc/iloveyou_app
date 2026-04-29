import Foundation

public enum FruitWheelCalculator {
    public static let sliceCount = 12

    public static func finalRotationDegrees(for wheelIndex: Int, fullTurns: Int) -> Double {
        precondition(0..<sliceCount ~= wheelIndex)
        precondition(5...7 ~= fullTurns)
        let sliceAngle = 360.0 / Double(sliceCount)
        let targetCenter = Double(wheelIndex) * sliceAngle + sliceAngle / 2.0
        return Double(fullTurns) * 360.0 + targetCenter
    }

    public static func randomizedFinalRotationDegrees(for wheelIndex: Int) -> Double {
        finalRotationDegrees(for: wheelIndex, fullTurns: Int.random(in: 5...7))
    }

    public static func landedWheelIndex(for rotationDegrees: Double) -> Int {
        let sliceAngle = 360.0 / Double(sliceCount)
        let normalized = rotationDegrees.truncatingRemainder(dividingBy: 360.0)
        return Int(normalized / sliceAngle)
    }
}
