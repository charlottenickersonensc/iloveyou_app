import XCTest
@testable import iLoveYouAppCore

final class FruitWheelCalculatorTests: XCTestCase {
    func testLandingCalculationTargetsAssignedSliceCenter() {
        let rotation = FruitWheelCalculator.finalRotationDegrees(for: 7, fullTurns: 5)
        XCTAssertEqual(rotation, 1800 + 225, accuracy: 0.001)
        XCTAssertEqual(FruitWheelCalculator.landedWheelIndex(for: rotation), 7)
    }

    func testAllWheelIndexesLandOnThemselves() {
        for index in 0..<FruitWheelCalculator.sliceCount {
            let rotation = FruitWheelCalculator.finalRotationDegrees(for: index, fullTurns: 6)
            XCTAssertEqual(FruitWheelCalculator.landedWheelIndex(for: rotation), index)
        }
    }
}
