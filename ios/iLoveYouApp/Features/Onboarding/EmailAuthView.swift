import SwiftUI
import AuthenticationServices

public struct EmailAuthView: View {
    @StateObject private var viewModel: EmailAuthViewModel
    private let appleSignInCoordinator = AppleSignInCoordinator()

    public init(viewModel: EmailAuthViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 1 email auth screen.
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(EmailAuthMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    AppTextField("Email", text: $viewModel.email)
                    SecureField("Password", text: $viewModel.password)
                        .padding(DesignTokens.Spacing.md)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

                    if viewModel.mode == .register {
                        AppTextField("Username", text: $viewModel.username)
                        AppTextField("Display name", text: $viewModel.displayUsername)
                        AppTextField("Date of birth YYYY-MM-DD", text: $viewModel.dateOfBirth)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    AppButton(viewModel.mode == .register ? "Create account" : "Log in", isLoading: viewModel.isLoading) {
                        Task { await viewModel.submit() }
                    }

                    SignInWithAppleButton(.signIn) { request in
                        appleSignInCoordinator.configure(request)
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("iLoveYou")
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let rawNonce = appleSignInCoordinator.consumeNonce(),
                let identityToken = credential.identityToken,
                let identityTokenString = String(data: identityToken, encoding: .utf8)
            else {
                viewModel.setError("Apple sign-in did not return a usable identity token.")
                return
            }
            Task {
                await viewModel.signInWithApple(token: AppleSignInToken(
                    identityToken: identityTokenString,
                    rawNonce: rawNonce,
                    fullName: credential.fullName
                ))
            }
        case .failure(let error):
            viewModel.setError(error.localizedDescription)
        }
    }
}
