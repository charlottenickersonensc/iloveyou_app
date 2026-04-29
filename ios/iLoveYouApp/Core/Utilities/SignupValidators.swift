import Foundation

public enum ValidationError: LocalizedError, Equatable {
    case invalidEmail
    case invalidUsername
    case invalidPassword
    case invalidDisplayUsername
    case invalidDateOfBirth
    case invalidBio
    case invalidInterest
    case tooManyInterests

    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case .invalidUsername:
            return "Username must be 3 to 20 lowercase letters, numbers, or underscores."
        case .invalidPassword:
            return "Password must be 3 to 20 characters and include at least one symbol."
        case .invalidDisplayUsername:
            return "Display name must be 1 to 30 characters."
        case .invalidDateOfBirth:
            return "Enter a valid date of birth."
        case .invalidBio:
            return "Bio must be 300 characters or fewer."
        case .invalidInterest:
            return "Each interest must start with # and be 30 characters or fewer."
        case .tooManyInterests:
            return "Add no more than 20 interests."
        }
    }
}

public enum SignupValidators {
    private static let symbolCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{};' :\"\\|,.<>/?`")

    public static func validateEmail(_ email: String) throws {
        if email.contains("@") == false || email.contains(".") == false {
            throw ValidationError.invalidEmail
        }
    }

    public static func validateUsername(_ username: String) throws {
        if username.range(of: "^[a-z0-9_]{3,20}$", options: .regularExpression) == nil {
            throw ValidationError.invalidUsername
        }
    }

    public static func validatePassword(_ password: String) throws {
        if password.count < 3 || password.count > 20 || password.rangeOfCharacter(from: symbolCharacters) == nil {
            throw ValidationError.invalidPassword
        }
    }

    public static func validateDisplayUsername(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.count > 30 {
            throw ValidationError.invalidDisplayUsername
        }
    }

    public static func validateDateOfBirth(_ value: String) throws {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: value), formatter.string(from: date) == value else {
            throw ValidationError.invalidDateOfBirth
        }
        let age = Calendar(identifier: .gregorian).dateComponents([.year], from: date, to: Date()).year ?? 0
        if age < 13 || age > 120 {
            throw ValidationError.invalidDateOfBirth
        }
    }
}

public enum ProfileValidators {
    public static func validate(input: UpdateProfileInput) throws {
        try SignupValidators.validateDisplayUsername(input.displayUsername)
        if let bio = input.bio, bio.count > 300 {
            throw ValidationError.invalidBio
        }
        if input.interests.count > 20 {
            throw ValidationError.tooManyInterests
        }
        for interest in input.interests {
            if interest.range(of: "^#[a-z0-9_]{1,29}$", options: .regularExpression) == nil {
                throw ValidationError.invalidInterest
            }
        }
    }
}
