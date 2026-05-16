import AppKit
import SwiftUI

@available(*, deprecated, message: "Use KikiSettingsShell, KikiSettingsPane, and the KikiSettings row components instead.")
public enum KikiSettingsUI {
    public struct FormPane<Content: View>: View {
        private let content: Content

        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        public var body: some View {
            Form {
                content
            }
            .formStyle(.grouped)
        }
    }

    public struct LinkButton: View {
        private let title: String
        private let urlString: String
        private let systemImage: String?

        public init(title: String, urlString: String, systemImage: String? = nil) {
            self.title = title
            self.urlString = urlString
            self.systemImage = systemImage
        }

        public var body: some View {
            Button {
                KikiSettingsActions.openURL(urlString)
            } label: {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .buttonStyle(.link)
        }
    }

    public struct CopyRow: View {
        private let title: String
        private let value: String
        private let systemImage: String?

        public init(title: String, value: String, systemImage: String? = nil) {
            self.title = title
            self.value = value
            self.systemImage = systemImage
        }

        public var body: some View {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
            } label: {
                HStack(spacing: KikiSettingsSpacing.sm) {
                    if let systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }
                    Spacer(minLength: 0)
                    Text(value)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    public typealias AppIdentityView = KikiAppIdentityView
    public typealias ApplicationRow = KikiSettingsApplicationRow
    public typealias ApplicationPicker = KikiSettingsApplicationPicker

    public static func openURL(_ urlString: String) {
        KikiSettingsActions.openURL(urlString)
    }
}
