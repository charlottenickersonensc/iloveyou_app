import SwiftUI

public struct AppTextField: View {
    private let title: String
    @Binding private var text: String

    public init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    public var body: some View {
        TextField(title, text: $text)
            .autocorrectionDisabled()
            .padding(DesignTokens.Spacing.md)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}
