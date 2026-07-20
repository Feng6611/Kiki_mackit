import SwiftUI

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

                ForEach(borderedSecondaryActions) { secondary in
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
            VStack(spacing: 8) {
                if footerLinkActions.isEmpty == false {
                    HStack(spacing: 10) {
                        ForEach(Array(footerLinkActions.enumerated()), id: \.element.id) { index, action in
                            if index > 0 {
                                KikiPaywallDotSeparator()
                            }
                            KikiPaywallLinkActionButton(action: action, tint: tint)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                footer
            }
        }
    }

    private var borderedSecondaryActions: [KikiPaywallActionConfig] {
        secondaryActions.filter { $0.style == .bordered }
    }

    private var footerLinkActions: [KikiPaywallActionConfig] {
        secondaryActions.filter { $0.style == .footerLink }
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
