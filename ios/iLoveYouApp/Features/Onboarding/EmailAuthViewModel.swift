import Combine
import Foundation

public enum EmailAuthMode: String, CaseIterable, Identifiable {
    case register = "Register"
    case login = "Log in"

    public var id: String { rawValue }
}

@MainActor
public final class EmailAuthViewModel: ObservableObject {
    @Published public var mode: EmailAuthMode = .register
    @Published public var email = ""
    @Published public var password = ""
    @Published public var username = ""
    @Published public var displayUsername = ""
    @Published public var dateOfBirth = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let authRepository: AuthRepository
    private let profileRepository: ProfileRepository
    private let onAuthenticated: (User) -> Void

    public init(
        authRepository: AuthRepository,
        profileRepository: ProfileRepository,
        onAuthenticated: @escaping (User) -> Void
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.onAuthenticated = onAuthenticated
    }

    public func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .register:
                try SignupValidators.validateEmail(email)
                try SignupValidators.validatePassword(password)
                try SignupValidators.validateUsername(username)
                try SignupValidators.validateDisplayUsername(displayUsername)
                try SignupValidators.validateDateOfBirth(dateOfBirth)
                _ = try await authRepository.registerWithEmail(email: email, password: password)
                let user = try await authRepository.completeSignup(input: CompleteSignupInput(
                    username: username,
                    displayUsername: displayUsername,
                    dateOfBirth: dateOfBirth
                ))
                onAuthenticated(user)
            case .login:
                try SignupValidators.validateEmail(email)
                _ = try await authRepository.signInWithEmail(email: email, password: password)
                let user = try await profileRepository.fetchMe()
                onAuthenticated(user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signInWithApple(token: AppleSignInToken) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await authRepository.signInWithApple(token: token)
            let user = try await profileRepository.fetchMe()
            onAuthenticated(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func setError(_ message: String) {
        errorMessage = message
    }
}
