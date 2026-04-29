import SwiftUI

public struct AppButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .minHeight(48)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}

private extension View {
    func minHeight(_ height: CGFloat) -> some View {
        frame(minHeight: height)
    }
}
