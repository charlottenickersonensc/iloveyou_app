import SwiftUI

public struct ProfileCreationView: View {
    @StateObject private var viewModel: ProfileCreationViewModel

    public init(viewModel: ProfileCreationViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 1 profile creation screen.
        Form {
            Section("Profile") {
                TextField("Display name", text: $viewModel.displayUsername)
                TextField("Pronouns", text: $viewModel.pronouns)
                TextField("Location", text: $viewModel.locationText)
                TextField("Bio", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Interests, like #music #books", text: $viewModel.interestsText)
                Toggle("Private profile", isOn: $viewModel.isPrivate)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            AppButton("Save profile", isLoading: viewModel.isLoading) {
                Task { await viewModel.save() }
            }
        }
        .navigationTitle("Profile")
    }
}
