import Combine
import Foundation

@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public private(set) var user: User
    @Published public private(set) var fruit: FruitCommunity?
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let profileRepository: ProfileRepository

    public init(user: User, profileRepository: ProfileRepository) {
        self.user = user
        self.profileRepository = profileRepository
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await profileRepository.fetchMe()
            fruit = try await profileRepository.fetchFruit(id: user.fruitCommunityId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
