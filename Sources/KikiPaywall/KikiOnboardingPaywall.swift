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
        KikiPaywallShell(
            width: KikiPaywallDefaults.onboardingSheetWidth,
            height: KikiPaywallDefaults.onboardingSheetHeight,
            tint: tint,
            showsCloseButton: presentation.dismiss != nil,
            onClose: presentation.dismiss
        ) {
            KikiPaywallHeader(
                title: presentation.headerTitle,
                subtitle: presentation.headerSubtitle
            )
        } content: {
            VStack(spacing: 16) {
                if presentation.stats.isEmpty == false {
                    HStack(spacing: 10) {
                        ForEach(presentation.stats) { stat in
                            KikiPaywallStatItem(value: stat.value, label: stat.label, tint: tint)
                        }
                    }
                }

                if presentation.features.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(presentation.features, id: \.self) { feature in
                            KikiPaywallFeatureRow(
                                icon: "checkmark.circle.fill",
                                text: feature,
                                tint: tint
                            )
                        }
                    }
                }

                if presentation.plans.isEmpty == false {
                    VStack(spacing: 10) {
                        ForEach(presentation.plans) { plan in
                            KikiPaywallPlanRow(
                                plan: plan.paywallPlan,
                                isSelected: selectedPlanID == plan.id,
                                tint: tint,
                                onSelect: { selectedPlanID = plan.id }
                            )
                        }
                    }
                }
            }
        } actions: {
            VStack(spacing: 8) {
                Button {
                    presentation.primaryAction.perform(selectedPlanID: selectedPlanID)
                } label: {
                    KikiPaywallActionLabel(
                        title: presentation.primaryAction.title,
                        isLoading: presentation.primaryAction.isLoading,
                        isProminent: true,
                        tint: tint
                    )
                }
                .buttonStyle(.plain)
                .disabled(primaryIsEnabled == false)
                .opacity(primaryIsEnabled ? 1 : 0.45)

                ForEach(presentation.secondaryActions) { secondaryAction in
                    Button {
                        secondaryAction.perform(selectedPlanID: selectedPlanID)
                    } label: {
                        KikiPaywallActionLabel(
                            title: secondaryAction.title,
                            isLoading: secondaryAction.isLoading,
                            isProminent: false,
                            tint: tint
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(secondaryIsEnabled(secondaryAction) == false)
                    .opacity(secondaryIsEnabled(secondaryAction) ? 1 : 0.45)
                }
            }
        } footer: {
            KikiPaywallPresentationFooter(presentation: presentation)
        }
    }

    private var primaryIsEnabled: Bool {
        presentation.isInteractionDisabled == false
            && presentation.primaryAction.isEnabled(for: selectedPlanID)
    }

    private func secondaryIsEnabled(_ action: KikiPaywallActionPresentation) -> Bool {
        presentation.isInteractionDisabled == false
            && action.isEnabled(for: selectedPlanID)
    }
}
