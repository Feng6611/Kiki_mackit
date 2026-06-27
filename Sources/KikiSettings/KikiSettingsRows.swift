import AppKit
import KikiDesign
import SwiftUI

public enum KikiSettingsStatusTone {
    case neutral
    case success
    case warning
    case accent

    var foregroundStyle: Color {
        switch self {
        case .neutral:
            return .secondary
        case .success:
            return .green
        case .warning:
            return .orange
        case .accent:
            return Color(red: 0.58, green: 0.20, blue: 0.62)
        }
    }

    var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }

    var usesBadge: Bool {
        switch self {
        case .warning, .accent:
            return true
        case .neutral, .success:
            return false
        }
    }
}

public struct KikiSettingsStatusRow: View {
    private let title: String
    private let value: String
    private let systemImage: String?
    private let tone: KikiSettingsStatusTone
    private let valueColor: Color?
    private let trailingSystemImage: String?
    private let action: (() -> Void)?

    public init(
        title: String,
        value: String,
        systemImage: String? = nil,
        tone: KikiSettingsStatusTone = .neutral,
        valueColor: Color? = nil,
        trailingSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.tone = tone
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
                .focusable(false)
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        KikiSettingsValueRow(title, systemImage: systemImage) {
            statusValue
            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.caption)
                    .foregroundStyle(tone.foregroundStyle)
            }
        }
    }

    @ViewBuilder
    private var statusValue: some View {
        if tone.usesBadge {
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(tone.foregroundStyle)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(tone.backgroundStyle)
                )
        } else {
            Text(value)
                .foregroundStyle(valueColor ?? tone.foregroundStyle)
                .lineLimit(1)
        }
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
            .frame(width: controlWidth)

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

public struct KikiSettingsValueRow<Content: View>: View {
    private let title: String
    private let systemImage: String?
    private let content: Content

    public init(
        _ title: String,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    public var body: some View {
        LabeledContent {
            HStack(spacing: KikiSettingsSpacing.sm) {
                content
            }
        } label: {
            KikiSettingsRowLabel(title: title, systemImage: systemImage)
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
        .focusable(false)
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
        .focusable(false)
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

    var body: some View {
        HStack(spacing: KikiSettingsSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.body)
                    .frame(width: 22, alignment: .leading)
            }
            Text(title)
        }
    }
}
