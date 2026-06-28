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
            showsCloseButton: presentation.actions.dismiss != nil,
            onClose: presentation.actions.dismiss
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
                    primaryAction()
                } label: {
                    KikiPaywallActionLabel(
                        title: primaryTitle,
                        isLoading: presentation.isPurchaseInFlight,
                        isProminent: true,
                        tint: tint
                    )
                }
                .buttonStyle(.plain)
                .disabled(presentation.isPurchaseInFlight)
                .opacity(presentation.isPurchaseInFlight ? 0.45 : 1)

                Button {
                    presentation.actions.restore()
                } label: {
                    KikiPaywallActionLabel(
                        title: "Restore purchases",
                        isLoading: presentation.isRestoreInFlight,
                        isProminent: false,
                        tint: tint
                    )
                }
                .buttonStyle(.plain)
                .disabled(presentation.isRestoreInFlight)
                .opacity(presentation.isRestoreInFlight ? 0.45 : 1)
            }
        } footer: {
            if let footnote = presentation.footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var primaryTitle: String {
        if presentation.canStartTrial {
            return "Start free trial"
        }
        return presentation.primaryButtonTitle
    }

    private func primaryAction() {
        if presentation.canStartTrial, let startTrial = presentation.actions.startTrial {
            startTrial()
            return
        }
        let planID = selectedPlanID
        guard planID.isEmpty == false else { return }
        presentation.actions.purchase(planID)
    }
}
