import SwiftUI

enum KikiSettingsSpacing {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let xl: CGFloat = 20
}

public struct KikiSettingsPane<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        Form {
            content
        }
        .kikiSettingsPaneChrome()
    }
}

public struct KikiSettingsHelperText: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func kikiSettingsPaneChrome() -> some View {
        formStyle(.grouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

public extension View {
    func kikiSettingDescription() -> some View {
        font(.caption)
            .foregroundStyle(.secondary)
    }
}
