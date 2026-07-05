import SwiftUI

public struct KikiOnboardingPaywall: View {
    private let presentation: KikiPaywallPresentation
    @Binding private var selectedPlanID: String
    private let tint: Color

    public init(
        presentation: KikiPaywallPresentation,
        selectedPlanID: Binding<String>,
        tint: Color = .accentColor
    ) {
        self.presentation = presentation
        self._selectedPlanID = selectedPlanID
        self.tint = tint
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
            size: .onboarding,
            showsCloseButton: presentation.dismiss != nil,
            onClose: presentation.dismiss
        ) {
            KikiPaywallPresentationFooter(presentation: presentation)
        }
    }

    private var primaryAction: KikiPaywallActionConfig {
        let planID = selectedPlanID
        return KikiPaywallActionConfig(
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
                title: action.title,
                isLoading: action.isLoading,
                isEnabled: presentation.isInteractionDisabled == false
                    && action.isEnabled(for: planID),
                action: { action.perform(selectedPlanID: planID) }
            )
        }
    }
}
