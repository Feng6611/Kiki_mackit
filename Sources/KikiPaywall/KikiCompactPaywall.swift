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
            secondaryActions: secondaryActions,
            tint: tint,
            size: .compact,
            showsCloseButton: showsCloseButton,
            onClose: presentation.dismiss
        ) {
            KikiPaywallPresentationFooter(presentation: presentation)
        }
    }

    private var primaryAction: KikiPaywallActionConfig {
        let planID = selectedPlanID
        return KikiPaywallActionConfig(
            id: presentation.primaryAction.id,
            title: presentation.primaryAction.title,
            isLoading: presentation.primaryAction.isLoading,
            isEnabled: presentation.isInteractionDisabled == false
                && presentation.primaryAction.isEnabled(for: planID),
            action: { presentation.primaryAction.perform(selectedPlanID: planID) }
        )
    }

    private var secondaryActions: [KikiPaywallActionConfig] {
        let planID = selectedPlanID
        return presentation.secondaryActions.map { action in
            KikiPaywallActionConfig(
                id: action.id,
                title: action.title,
                isLoading: action.isLoading,
                isEnabled: presentation.isInteractionDisabled == false
                    && action.isEnabled(for: planID),
                action: { action.perform(selectedPlanID: planID) }
            )
        }
    }
}
