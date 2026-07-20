import AppKit
import KikiDesign
import KikiWindow
import SwiftUI

public enum KikiPaywallDefaults {
    public static let sheetWidth: CGFloat = 500
    public static let sheetHeight: CGFloat = 520
    public static let onboardingSheetWidth: CGFloat = 520
    public static let onboardingSheetHeight: CGFloat = 520
    public static let windowWidth: CGFloat = 520
    public static let windowHeight: CGFloat = 620
    public static let sheetPadding: CGFloat = 28
}

public enum KikiPaywallSheetSize: Sendable {
    case compact
    case onboarding

    public var width: CGFloat {
        switch self {
        case .compact: return KikiPaywallDefaults.sheetWidth
        case .onboarding: return KikiPaywallDefaults.onboardingSheetWidth
        }
    }

    public var height: CGFloat {
        switch self {
        case .compact: return KikiPaywallDefaults.sheetHeight
        case .onboarding: return KikiPaywallDefaults.onboardingSheetHeight
        }
    }
}

@MainActor
public final class KikiPaywallWindowController<Content: View> {
    private let windowController: KikiSingleWindowController<Content>

    public init(
        title: String = "Upgrade",
        size: CGSize = CGSize(
            width: KikiPaywallDefaults.windowWidth,
            height: KikiPaywallDefaults.windowHeight
        ),
        minimumSize: CGSize? = nil,
        frameAutosaveName: String? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.windowController = KikiSingleWindowController(
            configuration: .utility(
                title: title,
                size: size,
                minimumSize: minimumSize,
                frameAutosaveName: frameAutosaveName
            ),
            onClose: onClose,
            content: content
        )
    }

    public var isVisible: Bool {
        windowController.isVisible
    }

    public func show() {
        windowController.show()
    }

    public func close() {
        windowController.close()
    }
}

public struct KikiPaywallPlan: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let displayPrice: String
    public let originalPrice: String?
    public let billingDetail: String
    public let badge: String?
    public let isAvailable: Bool

    public init(
        id: String,
        title: String,
        displayPrice: String,
        originalPrice: String? = nil,
        billingDetail: String,
        badge: String? = nil,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.displayPrice = displayPrice
        self.originalPrice = originalPrice
        self.billingDetail = billingDetail
        self.badge = badge
        self.isAvailable = isAvailable
    }
}

public struct KikiPaywallHeaderConfig {
    public let title: String
    public let subtitle: String
    public let icon: NSImage?

    public init(
        title: String,
        subtitle: String,
        icon: NSImage? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

/// Two configs with the same `value` and `label` derive the same `id` and
/// are treated as one element by `ForEach`. Pass an explicit `id` when the
/// same stat must appear more than once.
public struct KikiPaywallStatConfig: Identifiable, Equatable {
    public let id: String
    public let value: String
    public let label: String

    public init(id: String? = nil, value: String, label: String) {
        self.id = id ?? "\(value)\u{1F}\(label)"
        self.value = value
        self.label = label
    }
}

public struct KikiPaywallActionConfig: Identifiable {
    public let id: UUID
    public let title: String
    public let isLoading: Bool
    public let isEnabled: Bool
    public let action: @MainActor () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = UUID()
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public init(
        id: UUID,
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
}

public struct KikiPaywallSheet<Footer: View>: View {
    private let header: KikiPaywallHeaderConfig
    private let stats: [KikiPaywallStatConfig]
    private let features: [String]
    private let plans: [KikiPaywallPlan]
    @Binding private var selectedPlanID: String
    private let primary: KikiPaywallActionConfig
    private let secondaryActions: [KikiPaywallActionConfig]
    private let tint: Color
    private let size: KikiPaywallSheetSize
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let footer: Footer

    public init(
        header: KikiPaywallHeaderConfig,
        stats: [KikiPaywallStatConfig] = [],
        features: [String] = [],
        plans: [KikiPaywallPlan],
        selectedPlanID: Binding<String>,
        primary: KikiPaywallActionConfig,
        secondary: KikiPaywallActionConfig? = nil,
        tint: Color = .accentColor,
        size: KikiPaywallSheetSize = .compact,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header
        self.stats = stats
        self.features = features
        self.plans = plans
        self._selectedPlanID = selectedPlanID
        self.primary = primary
        self.secondaryActions = secondary.map { [$0] } ?? []
        self.tint = tint
        self.size = size
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.footer = footer()
    }

    public init(
        header: KikiPaywallHeaderConfig,
        stats: [KikiPaywallStatConfig] = [],
        features: [String] = [],
        plans: [KikiPaywallPlan],
        selectedPlanID: Binding<String>,
        primary: KikiPaywallActionConfig,
        secondaryActions: [KikiPaywallActionConfig],
        tint: Color = .accentColor,
        size: KikiPaywallSheetSize = .compact,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header
        self.stats = stats
        self.features = features
        self.plans = plans
        self._selectedPlanID = selectedPlanID
        self.primary = primary
        self.secondaryActions = secondaryActions
        self.tint = tint
        self.size = size
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.footer = footer()
    }

    public var body: some View {
        KikiPaywallShell(
            width: size.width,
            height: size.height,
            tint: tint,
            showsCloseButton: showsCloseButton,
            onClose: onClose
        ) {
            KikiPaywallHeader(
                title: header.title,
                subtitle: header.subtitle,
                icon: header.icon
            )
        } content: {
            VStack(spacing: 14) {
                if stats.isEmpty == false {
                    KikiPaywallStatsCard(stats: stats, tint: tint)
                }

                if features.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(features, id: \.self) { feature in
                            KikiPaywallFeatureRow(
                                icon: "checkmark.circle.fill",
                                text: feature,
                                tint: tint
                            )
                        }
                    }
                }

                if plans.isEmpty == false {
                    HStack(spacing: 10) {
                        ForEach(plans) { plan in
                            KikiPaywallPlanCard(
                                plan: plan,
                                isSelected: selectedPlanID == plan.id,
                                tint: tint,
                                onSelect: {
                                    selectedPlanID = plan.id
                                }
                            )
                        }
                    }
                }
            }
        } actions: {
            VStack(spacing: 8) {
                Button {
                    primary.action()
                } label: {
                    KikiPaywallActionLabel(
                        title: primary.title,
                        isLoading: primary.isLoading,
                        tint: tint
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint)
                .disabled(!primary.isEnabled)
                .keyboardShortcut(.defaultAction)

                ForEach(secondaryActions) { secondary in
                    Button {
                        secondary.action()
                    } label: {
                        KikiPaywallActionLabel(
                            title: secondary.title,
                            isLoading: secondary.isLoading,
                            tint: tint
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!secondary.isEnabled)
                }
            }
        } footer: {
            footer
        }
    }
}

public extension KikiPaywallSheet where Footer == EmptyView {
    init(
        header: KikiPaywallHeaderConfig,
        stats: [KikiPaywallStatConfig] = [],
        features: [String] = [],
        plans: [KikiPaywallPlan],
        selectedPlanID: Binding<String>,
        primary: KikiPaywallActionConfig,
        secondary: KikiPaywallActionConfig? = nil,
        tint: Color = .accentColor,
        size: KikiPaywallSheetSize = .compact,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil
    ) {
        self.init(
            header: header,
            stats: stats,
            features: features,
            plans: plans,
            selectedPlanID: selectedPlanID,
            primary: primary,
            secondary: secondary,
            tint: tint,
            size: size,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            footer: { EmptyView() }
        )
    }

    init(
        header: KikiPaywallHeaderConfig,
        stats: [KikiPaywallStatConfig] = [],
        features: [String] = [],
        plans: [KikiPaywallPlan],
        selectedPlanID: Binding<String>,
        primary: KikiPaywallActionConfig,
        secondaryActions: [KikiPaywallActionConfig],
        tint: Color = .accentColor,
        size: KikiPaywallSheetSize = .compact,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil
    ) {
        self.init(
            header: header,
            stats: stats,
            features: features,
            plans: plans,
            selectedPlanID: selectedPlanID,
            primary: primary,
            secondaryActions: secondaryActions,
            tint: tint,
            size: size,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            footer: { EmptyView() }
        )
    }
}

public struct KikiPaywallShell<Header: View, Content: View, Actions: View, Footer: View>: View {
    private let width: CGFloat
    private let height: CGFloat
    private let horizontalPadding: CGFloat
    private let tint: Color
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let header: Header
    private let content: Content
    private let actions: Actions
    private let footer: Footer

    public init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        height: CGFloat = KikiPaywallDefaults.sheetHeight,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder footer: () -> Footer
    ) {
        self.width = width
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.tint = tint
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.header = header()
        self.content = content()
        self.actions = actions()
        self.footer = footer()
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header
                            .padding(.top, 8)
                        content
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 14)
                }

                VStack(spacing: 8) {
                    actions
                    footer
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 14)
            }

            if showsCloseButton {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2.weight(.medium))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(20)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Close")
            }
        }
        .frame(width: width, height: height)
        .background {
            ZStack {
                KikiMaterialSurface(in: Rectangle(), material: .regularMaterial, tint: tint, tintOpacity: 0.025)
                RadialGradient(
                    colors: [tint.opacity(0.05), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 350
                )
            }
        }
    }
}

public extension KikiPaywallShell where Actions == EmptyView, Footer == EmptyView {
    init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        height: CGFloat = KikiPaywallDefaults.sheetHeight,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            width: width,
            height: height,
            horizontalPadding: horizontalPadding,
            tint: tint,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            header: header,
            content: content,
            actions: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

public struct KikiPaywallHeader: View {
    private let title: String
    private let subtitle: String
    private let icon: NSImage?
    private let iconSize: CGFloat

    public init(
        title: String,
        subtitle: String,
        icon: NSImage? = nil,
        iconSize: CGFloat = 80
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon ?? NSApplication.shared.applicationIconImage
        self.iconSize = iconSize
    }

    public var body: some View {
        VStack(spacing: 12) {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.iconLarge, style: .continuous))
                    .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
            }

            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

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

public struct KikiPaywallPlanCard: View {
    private let plan: KikiPaywallPlan
    private let isSelected: Bool
    private let tint: Color
    private let onSelect: () -> Void

    public init(
        plan: KikiPaywallPlan,
        isSelected: Bool,
        tint: Color = .accentColor,
        onSelect: @escaping () -> Void
    ) {
        self.plan = plan
        self.isSelected = isSelected
        self.tint = tint
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                if let badge = plan.badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(tint.opacity(KikiDesignTokens.Opacity.strongFill)))
                }

                Text(plan.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let originalPrice = plan.originalPrice {
                        Text(originalPrice)
                            .font(.callout)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Text(plan.displayPrice)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }

                Text(plan.billingDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .fill(isSelected ? tint.opacity(KikiDesignTokens.Opacity.subtleFill) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? tint : Color(nsColor: .separatorColor).opacity(KikiDesignTokens.Separator.mutedOpacity),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!plan.isAvailable)
        .opacity(plan.isAvailable ? 1 : KikiDesignTokens.Opacity.disabledContent)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plan.title), \(plan.displayPrice), \(plan.billingDetail)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

public struct KikiPaywallPlanRow: View {
    private let plan: KikiPaywallPlan
    private let isSelected: Bool
    private let tint: Color
    private let priceSuffix: String?
    private let showsUnavailablePill: Bool
    private let isDisabled: Bool
    private let onSelect: () -> Void

    public init(
        plan: KikiPaywallPlan,
        isSelected: Bool,
        tint: Color = .accentColor,
        priceSuffix: String? = nil,
        showsUnavailablePill: Bool = true,
        isDisabled: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.plan = plan
        self.isSelected = isSelected
        self.tint = tint
        self.priceSuffix = priceSuffix
        self.showsUnavailablePill = showsUnavailablePill
        self.isDisabled = isDisabled
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                selectionIndicator

                HStack(spacing: 6) {
                    Text(plan.title)
                        .font(.callout.weight(.medium))

                    if let badge = plan.badge {
                        KikiPaywallPill(text: badge, tone: .accent, tint: tint)
                    }

                    if showsUnavailablePill, !plan.isAvailable {
                        KikiPaywallPill(text: "Unavailable", tone: .neutral, tint: tint)
                    }
                }

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let originalPrice = plan.originalPrice {
                        Text(originalPrice)
                            .font(.callout)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }

                    Text(plan.displayPrice)
                        .font(.headline)
                        .foregroundStyle(isSelected ? tint : .primary)

                    if let priceSuffix {
                        Text(priceSuffix)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .fill(isSelected ? tint.opacity(KikiDesignTokens.Opacity.subtleFill) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? tint.opacity(KikiDesignTokens.Opacity.selectedStrokeOpacity) : Color(nsColor: .separatorColor).opacity(KikiDesignTokens.Separator.mutedOpacity),
                        lineWidth: isSelected ? 1.25 : 0.75
                    )
            )
            .opacity(plan.isAvailable ? 1 : KikiDesignTokens.Opacity.disabledContent)
        }
        .buttonStyle(.plain)
        .disabled(!plan.isAvailable || isDisabled)
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? tint : Color(nsColor: .separatorColor),
                    lineWidth: 1.5
                )
                .frame(width: 18, height: 18)

            if isSelected {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
            }
        }
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
