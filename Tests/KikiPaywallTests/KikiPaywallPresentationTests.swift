import KikiPaywall
import SwiftUI
import Testing

@MainActor
struct KikiPaywallPresentationTests {
    @Test("Presentation reports start-trial availability when notStarted and startTrial provided")
    func canStartTrialWhenNotStartedWithCallback() {
        let presentation = KikiPaywallPresentation(
            accessState: .notStarted,
            headerTitle: "Choose your plan",
            headerSubtitle: "Start using all features",
            plans: [],
            actions: KikiPaywallActions(
                purchase: { _ in },
                restore: {},
                startTrial: {}
            )
        )
        #expect(presentation.canStartTrial)
    }

    @Test("Presentation hides start-trial when startTrial closure missing")
    func cannotStartTrialWithoutCallback() {
        let presentation = KikiPaywallPresentation(
            accessState: .notStarted,
            headerTitle: "Choose your plan",
            headerSubtitle: "Start using all features",
            plans: [],
            actions: KikiPaywallActions(
                purchase: { _ in },
                restore: {}
            )
        )
        #expect(presentation.canStartTrial == false)
    }

    @Test("Primary button title switches to manage when entitled")
    func primaryTitleSwitchesWhenEntitled() {
        let trial = KikiPaywallPresentation(
            accessState: .trial(daysRemaining: 3),
            headerTitle: "Trial",
            headerSubtitle: "Three days left",
            plans: [],
            actions: KikiPaywallActions(purchase: { _ in }, restore: {})
        )
        #expect(trial.primaryButtonTitle == "Continue")

        let entitled = KikiPaywallPresentation(
            accessState: .entitled(planTitle: "Pro"),
            headerTitle: "Pro",
            headerSubtitle: "All features unlocked",
            plans: [],
            actions: KikiPaywallActions(purchase: { _ in }, restore: {})
        )
        #expect(entitled.primaryButtonTitle == "Manage subscription")
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

    @Test("Compact paywall view is constructible with binding")
    func compactPaywallIsConstructible() {
        let presentation = KikiPaywallPresentation(
            accessState: .notStarted,
            headerTitle: "Choose your plan",
            headerSubtitle: "Try free for 7 days",
            plans: [
                KikiPaywallPlanPresentation(
                    id: "yearly",
                    title: "Yearly",
                    displayPrice: "$19.99",
                    billingDetail: "per year"
                )
            ],
            actions: KikiPaywallActions(purchase: { _ in }, restore: {})
        )
        let binding = Binding<String>(get: { "yearly" }, set: { _ in })
        _ = KikiCompactPaywall(presentation: presentation, selectedPlanID: binding)
        _ = KikiOnboardingPaywall(presentation: presentation, selectedPlanID: binding)
    }
}
