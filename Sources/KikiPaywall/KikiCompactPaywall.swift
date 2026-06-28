import SwiftUI

public struct KikiCompactPaywall: View {
    private let presentation: KikiPaywallPresentation
    @Binding private var selectedPlanID: String
    private let tint: Color
    private let showsCloseButton: Bool

    public init(
        presentation: KikiPaywallPresentation,
        selectedPlanID: Binding<String>,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false
    ) {
        self.presentation = presentation
        self._selectedPlanID = selectedPlanID
        self.tint = tint
        self.showsCloseButton = showsCloseButton
    }

    public var body: some View {
        KikiPaywallSheet(
            header: KikiPaywallHeaderConfig(
                title: presentation.headerTitle,
                subtitle: presentation.headerSubtitle
            ),
            stats: presentation.stats,
            features: presentation.features,
            plans: presentation.plans.map(\.paywallPlan),
            selectedPlanID: $selectedPlanID,
            primary: primaryAction,
            secondary: secondaryAction,
            tint: tint,
            showsCloseButton: showsCloseButton,
            onClose: presentation.actions.dismiss
        )
    }

    private var primaryAction: KikiPaywallActionConfig {
        if presentation.canStartTrial, let startTrial = presentation.actions.startTrial {
            return KikiPaywallActionConfig(
                title: "Start free trial",
                isLoading: presentation.isPurchaseInFlight,
                isEnabled: presentation.isPurchaseInFlight == false,
                action: startTrial
            )
        }
        let planID = selectedPlanID
        return KikiPaywallActionConfig(
            title: presentation.primaryButtonTitle,
            isLoading: presentation.isPurchaseInFlight,
            isEnabled: presentation.isPurchaseInFlight == false && planID.isEmpty == false,
            action: { presentation.actions.purchase(planID) }
        )
    }

    private var secondaryAction: KikiPaywallActionConfig? {
        KikiPaywallActionConfig(
            title: "Restore purchases",
            isLoading: presentation.isRestoreInFlight,
            isEnabled: presentation.isRestoreInFlight == false,
            action: presentation.actions.restore
        )
    }
}
