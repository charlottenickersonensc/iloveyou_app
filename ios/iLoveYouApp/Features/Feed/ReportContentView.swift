import SwiftUI

public struct ReportContentView: View {
    @Environment(\.dismiss) private var dismiss
    public let post: Post
    public let onSubmit: (ReportReason, String?) async -> Void
    @State private var selectedReason: ReportReason = .spam
    @State private var details = ""
    @State private var isSubmitting = false

    public init(post: Post, onSubmit: @escaping (ReportReason, String?) async -> Void) {
        self.post = post
        self.onSubmit = onSubmit
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 2 report sheet.
        NavigationStack {
            Form {
                Picker("Reason", selection: $selectedReason) {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Text(reason.displayTitle).tag(reason)
                    }
                }

                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Report post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            isSubmitting = true
                            let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
                            await onSubmit(selectedReason, trimmed.isEmpty ? nil : trimmed)
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
}
