import AppKit
import SwiftUI

public struct KikiSettingsStatusRow: View {
    private let title: String
    private let value: String
    private let systemImage: String
    private let valueColor: Color
    private let trailingSystemImage: String?
    private let action: (() -> Void)?

    public init(
        title: String,
        value: String,
        systemImage: String,
        valueColor: Color = .secondary,
        trailingSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.valueColor = valueColor
        self.trailingSystemImage = trailingSystemImage
        self.action = action
    }

    public var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: KikiSettingsSpacing.sm) {
            KikiSettingsRowTitle(title: title, systemImage: systemImage)
            Spacer(minLength: KikiSettingsSpacing.md)
            Text(value)
                .foregroundStyle(valueColor)
                .lineLimit(1)
            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

public struct KikiSettingsLinkRow: View {
    private let title: String
    private let value: String
    private let urlString: String
    private let systemImage: String
    private let trailingSystemImage: String

    public init(
        title: String,
        value: String,
        urlString: String,
        systemImage: String,
        trailingSystemImage: String = "arrow.up.right"
    ) {
        self.title = title
        self.value = value
        self.urlString = urlString
        self.systemImage = systemImage
        self.trailingSystemImage = trailingSystemImage
    }

    public var body: some View {
        Button {
            KikiSettingsActions.openURL(urlString)
        } label: {
            KikiSettingsRowContent(
                title: title,
                value: value,
                systemImage: systemImage,
                trailingSystemImage: trailingSystemImage
            )
        }
        .buttonStyle(.plain)
    }
}

public struct KikiSettingsCopyRow: View {
    private let title: String
    private let value: String
    private let systemImage: String
    private let trailingSystemImage: String

    public init(
        title: String,
        value: String,
        systemImage: String,
        trailingSystemImage: String = "doc.on.doc"
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.trailingSystemImage = trailingSystemImage
    }

    public var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
        } label: {
            KikiSettingsRowContent(
                title: title,
                value: value,
                systemImage: systemImage,
                trailingSystemImage: trailingSystemImage
            )
        }
        .buttonStyle(.plain)
    }
}

private struct KikiSettingsRowContent: View {
    let title: String
    let value: String
    let systemImage: String
    let trailingSystemImage: String

    var body: some View {
        HStack(spacing: KikiSettingsSpacing.sm) {
            KikiSettingsRowTitle(title: title, systemImage: systemImage)
            Spacer(minLength: KikiSettingsSpacing.md)
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Image(systemName: trailingSystemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct KikiSettingsRowTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: KikiSettingsSpacing.sm) {
            Image(systemName: systemImage)
                .font(.body)
                .frame(width: 22, alignment: .leading)
            Text(title)
        }
    }
}
