import KikiDesign
import SwiftUI

public struct KikiPaywallStatusHeader<Accessory: View>: View {
    private let title: String
    private let subtitle: String
    private let systemName: String
    private let iconColor: Color
    private let backgroundColor: Color
    private let iconSize: CGFloat
    private let accessory: Accessory

    public init(
        title: String,
        subtitle: String,
        systemName: String,
        iconColor: Color = .accentColor,
        backgroundColor: Color = .accentColor.opacity(KikiDesignTokens.Opacity.strongFill),
        iconSize: CGFloat = 46,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemName = systemName
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.iconSize = iconSize
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: 14) {
            KikiPaywallIconBadge(
                systemName: systemName,
                iconColor: iconColor,
                backgroundColor: backgroundColor,
                size: iconSize
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.bold))

                    accessory
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

public extension KikiPaywallStatusHeader where Accessory == EmptyView {
    init(
        title: String,
        subtitle: String,
        systemName: String,
        iconColor: Color = .accentColor,
        backgroundColor: Color = .accentColor.opacity(KikiDesignTokens.Opacity.strongFill),
        iconSize: CGFloat = 46
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            systemName: systemName,
            iconColor: iconColor,
            backgroundColor: backgroundColor,
            iconSize: iconSize,
            accessory: { EmptyView() }
        )
    }
}
