import Combine
import Foundation

@MainActor
public final class ProfileCreationViewModel: ObservableObject {
    @Published public var displayUsername: String
    @Published public var pronouns: String
    @Published public var locationText: String
    @Published public var bio: String
    @Published public var interestsText: String
    @Published public var isPrivate: Bool
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let user: User
    private let profileRepository: ProfileRepository
    private let onSaved: (User) -> Void

    public init(user: User, profileRepository: ProfileRepository, onSaved: @escaping (User) -> Void) {
        self.user = user
        self.profileRepository = profileRepository
        self.onSaved = onSaved
        self.displayUsername = user.displayUsername
        self.pronouns = user.pronouns ?? ""
        self.locationText = user.locationText ?? ""
        self.bio = user.bio ?? ""
        self.interestsText = user.interests.joined(separator: " ")
        self.isPrivate = user.isPrivate
    }

    public func save() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let interests = interestsText
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        do {
            let input = UpdateProfileInput(
                displayUsername: displayUsername,
                pronouns: pronouns.nilIfBlank,
                locationText: locationText.nilIfBlank,
                bio: bio.nilIfBlank,
                interests: interests,
                isPrivate: isPrivate
            )
            try ProfileValidators.validate(input: input)
            let updatedUser = try await profileRepository.updateProfile(input: input)
            onSaved(updatedUser)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
