import AppKit
import KikiDesign
import SwiftUI

public struct KikiPaywallStatItem: View {
    private let value: String
    private let label: String
    private let tint: Color

    public init(value: String, label: String, tint: Color = .accentColor) {
        self.value = value
        self.label = label
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

public struct KikiPaywallStatsCard: View {
    private let stats: [KikiPaywallStatConfig]
    private let tint: Color

    public init(stats: [KikiPaywallStatConfig], tint: Color = .accentColor) {
        self.stats = stats
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 10) {
            ForEach(stats) { stat in
                KikiPaywallStatItem(
                    value: stat.value,
                    label: stat.label,
                    tint: tint
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.panel, style: .continuous)
                .fill(tint.opacity(KikiDesignTokens.Opacity.mediumFill))
        )
    }
}

public struct KikiPaywallFeatureRow: View {
    private let icon: String
    private let text: String
    private let tint: Color

    public init(icon: String, text: String, tint: Color = .accentColor) {
        self.icon = icon
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

public struct KikiPaywallActionLabel: View {
    private let title: String
    private let isLoading: Bool
    private let tint: Color

    public init(
        title: String,
        isLoading: Bool,
        tint: Color = .accentColor
    ) {
        self.title = title
        self.isLoading = isLoading
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(tint)
            }

            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

public enum KikiPaywallPillTone {
    case accent
    case neutral
    case warning
    case success
    case danger
}

public struct KikiPaywallIconBadge: View {
    private let systemName: String
    private let iconColor: Color
    private let backgroundColor: Color
    private let size: CGFloat
    private let iconScale: CGFloat

    public init(
        systemName: String,
        iconColor: Color = .accentColor,
        backgroundColor: Color = .accentColor.opacity(KikiDesignTokens.Opacity.strongFill),
        size: CGFloat = 46,
        iconScale: CGFloat = 0.42
    ) {
        self.systemName = systemName
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.size = size
        self.iconScale = iconScale
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(.title3.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(iconColor)
            .frame(width: size, height: size)
            .background(Circle().fill(backgroundColor))
    }
}

public struct KikiPaywallPill: View {
    private let text: String
    private let tone: KikiPaywallPillTone
    private let tint: Color

    public init(
        text: String,
        tone: KikiPaywallPillTone = .accent,
        tint: Color = .accentColor
    ) {
        self.text = text
        self.tone = tone
        self.tint = tint
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(backgroundColor))
    }

    private var foregroundColor: Color {
        switch tone {
        case .accent:
            return tint
        case .neutral, .warning, .success, .danger:
            return color
        }
    }

    private var backgroundColor: Color {
        switch tone {
        case .accent:
            return tint.opacity(KikiDesignTokens.Opacity.strongFill)
        case .neutral, .warning, .success, .danger:
            return color.opacity(KikiDesignTokens.Opacity.badgeFill)
        }
    }

    private var color: Color {
        switch tone {
        case .accent:
            return tint
        case .neutral:
            return .secondary
        case .warning:
            return .orange
        case .success:
            return Color(nsColor: .systemGreen)
        case .danger:
            return .red
        }
    }
}

public struct KikiPaywallDotSeparator: View {
    private let color: Color
    private let size: CGFloat

    public init(
        color: Color = .secondary.opacity(0.35),
        size: CGFloat = 3
    ) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

public enum KikiPaywallMessageTone: Equatable, Sendable {
    case neutral
    case warning
    case success
    case danger
}

public struct KikiPaywallMessage: View {
    private let text: String
    private let tone: KikiPaywallMessageTone

    public init(
        _ text: String,
        tone: KikiPaywallMessageTone = .neutral
    ) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var color: Color {
        switch tone {
        case .neutral:
            return .secondary
        case .warning:
            return .orange
        case .success:
            return Color(nsColor: .systemGreen)
        case .danger:
            return .red
        }
    }
}

public struct KikiPaywallMetadataRow: View {
    private let title: String
    private let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(.primary)
        }
        .font(.callout)
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }
}

public extension View {
    func kikiPaywallCard(
        cornerRadius: CGFloat = KikiDesignTokens.CornerRadius.elevatedCard,
        shadowColor: Color = .black.opacity(0.05),
        shadowRadius: CGFloat = 18,
        shadowY: CGFloat = 8
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(KikiDesignTokens.Separator.mutedOpacity), lineWidth: 0.75)
        )
        .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }
}
