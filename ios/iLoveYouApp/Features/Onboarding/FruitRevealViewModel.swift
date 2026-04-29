import Combine
import Foundation

@MainActor
public final class FruitRevealViewModel: ObservableObject {
    public let user: User
    public let fruit: FruitCommunity
    @Published public var rotationDegrees: Double = 0
    @Published public var hasFinishedAnimation = false

    public init(user: User, fruits: [FruitCommunity] = FruitCommunity.sprintOneSeed) {
        self.user = user
        self.fruit = fruits.first(where: { $0.id == user.fruitCommunityId }) ?? fruits[0]
    }

    public func start() {
        rotationDegrees = FruitWheelCalculator.randomizedFinalRotationDegrees(for: fruit.wheelIndex)
    }

    public func finishAnimation() {
        hasFinishedAnimation = true
    }
}
