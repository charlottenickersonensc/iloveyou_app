import SwiftUI

public struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contentText = ""
    @State private var isSubmitting = false
    private let onSubmit: (String) async -> Void

    public init(onSubmit: @escaping (String) async -> Void) {
        self.onSubmit = onSubmit
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 2 composer, including image picker styling.
        NavigationStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                TextEditor(text: $contentText)
                    .frame(minHeight: 180)
                    .padding(DesignTokens.Spacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .stroke(Color.secondary.opacity(0.25))
                    )

                HStack {
                    Text("\(trimmed.count)/2000")
                        .font(.caption)
                        .foregroundStyle(trimmed.count > 2000 ? .red : .secondary)
                    Spacer()
                    Button("Post") {
                        Task {
                            isSubmitting = true
                            await onSubmit(trimmed)
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmed.isEmpty || trimmed.count > 2000 || isSubmitting)
                }

                Text("Image attachment placeholder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .navigationTitle("Create post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var trimmed: String {
        contentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
