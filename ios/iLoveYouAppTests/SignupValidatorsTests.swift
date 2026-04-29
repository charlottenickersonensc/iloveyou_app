import XCTest
@testable import iLoveYouAppCore

final class SignupValidatorsTests: XCTestCase {
    func testEmailRegistrationValidationAcceptsValidValues() throws {
        try SignupValidators.validateEmail("person@example.com")
        try SignupValidators.validatePassword("abc!")
        try SignupValidators.validateUsername("person_1")
        try SignupValidators.validateDisplayUsername("Person")
        try SignupValidators.validateDateOfBirth("2000-01-01")
    }

    func testPasswordRequiresSymbol() {
        XCTAssertThrowsError(try SignupValidators.validatePassword("abcdef"))
    }

    func testUsernameRejectsUppercaseAndShortValues() {
        XCTAssertThrowsError(try SignupValidators.validateUsername("Abc"))
        XCTAssertThrowsError(try SignupValidators.validateUsername("ab"))
    }

    func testProfileValidationRejectsTooManyInterests() {
        let input = UpdateProfileInput(
            displayUsername: "Person",
            pronouns: nil,
            locationText: nil,
            bio: nil,
            interests: Array(repeating: "#music", count: 21),
            isPrivate: false
        )
        XCTAssertThrowsError(try ProfileValidators.validate(input: input))
    }
}
