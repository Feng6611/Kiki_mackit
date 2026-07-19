import AppKit
import KikiDesign
import SwiftUI

public enum KikiSettingsStatusTone: Equatable, Sendable {
    case neutral
    case success
    case warning
    case accent
    case info

    var foregroundStyle: Color {
        switch self {
        case .neutral:
            return .secondary
        case .success:
            return .green
        case .warning:
            return .orange
        case .accent:
            return .accentColor
        case .info:
            return .blue
        }
    }

    var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }

    var usesBadge: Bool {
        switch self {
        case .warning, .accent:
            return true
        case .neutral, .success, .info:
            return false
        }
    }
}

public struct KikiSettingsStatusRow: View {
    private let title: String
    private let value: String
    private let systemImage: String?
    private let valueSystemImage: String?
    private let tone: KikiSettingsStatusTone
    private let tint: Color
    private let valueColor: Color?
    private let showsBadge: Bool?
    private let trailingSystemImage: String?
    private let action: (() -> Void)?

    public init(
        title: String,
        value: String,
        systemImage: String? = nil,
        valueSystemImage: String? = nil,
        tone: KikiSettingsStatusTone = .neutral,
        valueColor: Color? = nil,
        showsBadge: Bool? = nil,
        trailingSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.valueSystemImage = valueSystemImage
        self.tone = tone
        self.tint = .accentColor
        self.valueColor = valueColor
        self.showsBadge = showsBadge
        self.trailingSystemImage = trailingSystemImage
        self.action = action
    }

    public init(
        title: String,
        value: String,
        systemImage: String? = nil,
        valueSystemImage: String? = nil,
        tone: KikiSettingsStatusTone = .neutral,
        tint: Color,
        valueColor: Color? = nil,
        showsBadge: Bool? = nil,
        trailingSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.valueSystemImage = valueSystemImage
        self.tone = tone
        self.tint = tint
        self.valueColor = valueColor
        self.showsBadge = showsBadge
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

    private var resolvedForeground: Color {
        tone == .accent ? tint : tone.foregroundStyle
    }

    private var rowContent: some View {
        KikiSettingsValueRow(title, systemImage: systemImage, iconColor: .secondary) {
            statusValue
            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusValue: some View {
        if showsBadge ?? tone.usesBadge {
            statusLabel
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(resolvedForeground.opacity(0.12))
                )
        } else {
            statusLabel
        }
    }

    private var statusLabel: some View {
        HStack(spacing: 5) {
            if let valueSystemImage {
                Image(systemName: valueSystemImage)
                    .accessibilityHidden(true)
            }
            Text(value)
                .lineLimit(1)
        }
        .foregroundStyle(valueColor ?? resolvedForeground)
        .accessibilityElement(children: .combine)
    }
}

public struct KikiAuthorizationStatusRow: View {
    private let title: String
    private let isAuthorized: Bool
    private let authorizedValue: String
    private let unauthorizedValue: String
    private let systemImage: String
    private let allowsAuthorizedAction: Bool
    private let action: (() -> Void)?

    public init(
        title: String,
        isAuthorized: Bool,
        authorizedValue: String = "Allowed",
        unauthorizedValue: String = "Needed",
        systemImage: String = "accessibility",
        allowsAuthorizedAction: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.isAuthorized = isAuthorized
        self.authorizedValue = authorizedValue
        self.unauthorizedValue = unauthorizedValue
        self.systemImage = systemImage
        self.allowsAuthorizedAction = allowsAuthorizedAction
        self.action = action
    }

    public var body: some View {
        let rowAction = (!isAuthorized || allowsAuthorizedAction) ? action : nil
        KikiSettingsStatusRow(
            title: title,
            value: isAuthorized ? authorizedValue : unauthorizedValue,
            systemImage: systemImage,
            tone: isAuthorized ? .success : .warning,
            trailingSystemImage: rowAction == nil ? nil : "chevron.right",
            action: rowAction
        )
    }
}

public struct KikiSettingsSegmentedPickerRow<Value: Hashable>: View {
    private let title: String
    private let options: [Value]
    private let systemImage: String?
    private let controlWidth: CGFloat
    private let leadingCaption: String?
    private let trailingCaption: String?
    private let optionTitle: (Value) -> String
    @Binding private var selection: Value

    public init(
        _ title: String,
        selection: Binding<Value>,
        options: [Value],
        systemImage: String? = nil,
        controlWidth: CGFloat = 180,
        leadingCaption: String? = nil,
        trailingCaption: String? = nil,
        optionTitle: @escaping (Value) -> String
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.systemImage = systemImage
        self.controlWidth = controlWidth
        self.leadingCaption = leadingCaption
        self.trailingCaption = trailingCaption
        self.optionTitle = optionTitle
    }

    public var body: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            if let leadingCaption {
                caption(leadingCaption)
            }

            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(optionTitle(option)).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(minWidth: controlWidth, alignment: .trailing)

            if let trailingCaption {
                caption(trailingCaption)
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize()
    }
}

public struct KikiSettingsMenuPickerRow<Value: Hashable>: View {
    private let title: String
    private let options: [Value]
    private let systemImage: String?
    private let optionTitle: (Value) -> String
    @Binding private var selection: Value

    public init(
        _ title: String,
        selection: Binding<Value>,
        options: [Value],
        systemImage: String? = nil,
        optionTitle: @escaping (Value) -> String
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.systemImage = systemImage
        self.optionTitle = optionTitle
    }

    public var body: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(optionTitle(option)).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(minWidth: 140, alignment: .trailing)
        }
    }
}

public struct KikiSettingsDebugPreviewRow<Item: Hashable>: View {
    private let title: String
    private let systemImage: String?
    private let options: [Item]
    private let controlWidth: CGFloat
    private let isOverrideActive: Bool
    private let optionTitle: (Item) -> String
    @Binding private var selection: Item

    public init(
        _ title: String = "Test override",
        selection: Binding<Item>,
        options: [Item],
        systemImage: String? = "hammer",
        controlWidth: CGFloat = 320,
        isOverrideActive: Bool = true,
        optionTitle: @escaping (Item) -> String
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.systemImage = systemImage
        self.controlWidth = controlWidth
        self.isOverrideActive = isOverrideActive
        self.optionTitle = optionTitle
    }

    public var body: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(optionTitle(option)).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(minWidth: controlWidth, alignment: .trailing)
            .foregroundStyle(isOverrideActive ? .orange : .secondary)
        }
    }
}

public struct KikiSettingsValueRow<Content: View>: View {
    private let title: String
    private let systemImage: String?
    private let iconColor: Color?
    private let content: Content

    public init(
        _ title: String,
        systemImage: String? = nil,
        iconColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.content = content()
    }

    public var body: some View {
        LabeledContent {
            HStack(spacing: KikiSettingsSpacing.sm) {
                content
            }
        } label: {
            KikiSettingsRowLabel(title: title, systemImage: systemImage, iconColor: iconColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

public struct KikiSettingsToggleRow: View {
    private let title: String
    private let systemImage: String?
    @Binding private var isOn: Bool

    public init(
        _ title: String,
        isOn: Binding<Bool>,
        systemImage: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            KikiSettingsRowLabel(title: title, systemImage: systemImage)
        }
    }
}

public struct KikiSettingsStepperRow<Value: Strideable & Comparable>: View where Value.Stride: SignedNumeric {
    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let systemImage: String?
    private let valueText: (Value) -> String
    @Binding private var value: Value

    public init(
        _ title: String,
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride = 1,
        systemImage: String? = nil,
        valueText: @escaping (Value) -> String
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.systemImage = systemImage
        self.valueText = valueText
    }

    public var body: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            Text(valueText(value))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Stepper(value: $value, in: range, step: step) {
                Text(title)
            }
            .labelsHidden()
        }
    }
}

public struct KikiSettingsSliderRow: View {
    private let title: String
    private let range: ClosedRange<Double>
    private let step: Double?
    private let systemImage: String?
    private let controlWidth: CGFloat
    private let valueWidth: CGFloat
    private let valueText: (Double) -> String
    @Binding private var value: Double

    public init(
        _ title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        systemImage: String? = nil,
        controlWidth: CGFloat = 160,
        valueWidth: CGFloat = 48,
        valueText: @escaping (Double) -> String
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.systemImage = systemImage
        self.controlWidth = controlWidth
        self.valueWidth = valueWidth
        self.valueText = valueText
    }

    public var body: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            slider
                .labelsHidden()
                .frame(width: controlWidth)

            Text(valueText(value))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: valueWidth, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var slider: some View {
        if let step {
            Slider(value: $value, in: range, step: step) {
                Text(title)
            }
        } else {
            Slider(value: $value, in: range) {
                Text(title)
            }
        }
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
            KikiSettingsNavigationRowContent(
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
            KikiSettingsNavigationRowContent(
                title: title,
                value: value,
                systemImage: systemImage,
                trailingSystemImage: trailingSystemImage
            )
        }
        .buttonStyle(.plain)
    }
}

private struct KikiSettingsNavigationRowContent: View {
    let title: String
    let value: String
    let systemImage: String
    let trailingSystemImage: String

    var body: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Image(systemName: trailingSystemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct KikiSettingsRowLabel: View {
    let title: String
    let systemImage: String?
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: KikiSettingsSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(iconColor ?? .primary)
                    .frame(width: 22, alignment: .leading)
            }
            Text(title)
        }
    }
}
