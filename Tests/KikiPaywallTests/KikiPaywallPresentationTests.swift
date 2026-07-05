import Foundation
import KikiPaywall
import SwiftUI
import Testing

@MainActor
struct KikiPaywallPresentationTests {
    @Test("Primary action policy is supplied by the host")
    func hostSuppliesPrimaryActionPolicy() {
        var purchasedPlanID: String?
        let presentation = makePresentation(
            accessState: .notStarted,
            primaryAction: KikiPaywallActionPresentation(
                title: "Unlock forever",
                isEnabled: { planID in planID == "lifetime" },
                action: { purchasedPlanID = $0 }
            )
        )

        #expect(presentation.primaryAction.title == "Unlock forever")
        #expect(presentation.primaryAction.isEnabled(for: "missing") == false)

        presentation.primaryAction.perform(selectedPlanID: "missing")
        #expect(purchasedPlanID == nil)

        presentation.primaryAction.perform(selectedPlanID: "lifetime")
        #expect(purchasedPlanID == "lifetime")
    }

    @Test("Entitled host can supply a dismiss primary action")
    func entitledPrimaryActionDismissesWithoutPurchasing() {
        var didDismiss = false
        let presentation = makePresentation(
            accessState: .entitled(planTitle: "Pro"),
            plans: [],
            primaryAction: KikiPaywallActionPresentation(
                title: "Done",
                action: { didDismiss = true }
            ),
            dismiss: { didDismiss = true }
        )

        presentation.primaryAction.perform(selectedPlanID: "")

        #expect(didDismiss)
        #expect(presentation.primaryAction.title == "Done")
    }

    @Test("Presentation carries feedback, footnote, and footer links together")
    func presentationCarriesFooterContent() throws {
        let termsURL = try #require(URL(string: "https://example.com/terms"))
        let message = KikiPaywallMessagePresentation(
            text: "Purchase failed.",
            tone: .danger
        )
        let presentation = makePresentation(
            message: message,
            footnote: "Payment is handled by the App Store.",
            footerLinks: [
                KikiPaywallLinkPresentation(id: "terms", title: "Terms", url: termsURL)
            ]
        )

        #expect(presentation.message == message)
        #expect(presentation.footnote == "Payment is handled by the App Store.")
        #expect(presentation.footerLinks.map(\.id) == ["terms"])
    }

    @Test("Interaction disabled blocks both primary and secondary actions")
    func interactionDisabledBlocksActions() {
        var actionCount = 0
        let presentation = makePresentation(
            isInteractionDisabled: true,
            primaryAction: KikiPaywallActionPresentation(title: "Buy") {
                actionCount += 1
            },
            secondaryActions: [
                KikiPaywallActionPresentation(title: "Restore") {
                    actionCount += 1
                }
            ]
        )

        let primaryEnabled = presentation.isInteractionDisabled == false
            && presentation.primaryAction.isEnabled(for: "lifetime")
        let secondaryEnabled = presentation.isInteractionDisabled == false
            && presentation.secondaryActions.first?.isEnabled(for: "lifetime") == true

        #expect(primaryEnabled == false)
        #expect(secondaryEnabled == false)
        #expect(actionCount == 0)
    }

    @Test("Plan presentation maps to KikiPaywallPlan atom")
    func planPresentationMapsToAtom() {
        let plan = KikiPaywallPlanPresentation(
            id: "yearly",
            title: "Yearly",
            displayPrice: "$19.99",
            billingDetail: "per year",
            badge: "Best value"
        )
        let atom = plan.paywallPlan
        #expect(atom.id == "yearly")
        #expect(atom.badge == "Best value")
        #expect(atom.displayPrice == "$19.99")
    }

    @Test("Preset views are constructible with explicit actions")
    func presetViewsAreConstructible() {
        let presentation = makePresentation()
        let binding = Binding<String>(get: { "lifetime" }, set: { _ in })

        _ = KikiCompactPaywall(presentation: presentation, selectedPlanID: binding)
        _ = KikiOnboardingPaywall(presentation: presentation, selectedPlanID: binding)
    }

    private func makePresentation(
        accessState: KikiPaywallAccessState = .expired,
        plans: [KikiPaywallPlanPresentation] = [
            KikiPaywallPlanPresentation(
                id: "lifetime",
                title: "Lifetime",
                displayPrice: "$5.99",
                billingDetail: "once"
            )
        ],
        message: KikiPaywallMessagePresentation? = nil,
        footnote: String? = nil,
        footerLinks: [KikiPaywallLinkPresentation] = [],
        isInteractionDisabled: Bool = false,
        primaryAction: KikiPaywallActionPresentation = KikiPaywallActionPresentation(
            title: "Continue",
            action: {}
        ),
        secondaryActions: [KikiPaywallActionPresentation] = [],
        dismiss: (@MainActor () -> Void)? = nil
    ) -> KikiPaywallPresentation {
        KikiPaywallPresentation(
            accessState: accessState,
            headerTitle: "Choose your plan",
            headerSubtitle: "Unlock all features",
            plans: plans,
            footnote: footnote,
            footerLinks: footerLinks,
            message: message,
            isInteractionDisabled: isInteractionDisabled,
            primaryAction: primaryAction,
            secondaryActions: secondaryActions,
            dismiss: dismiss
        )
    }
}
