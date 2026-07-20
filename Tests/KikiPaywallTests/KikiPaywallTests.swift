import KikiPaywall
import SwiftUI
import Testing

struct KikiPaywallTests {
    @Test("Onboarding paywall stays within the welcome window")
    func onboardingPaywallStaysWithinWelcomeWindow() {
        #expect(KikiPaywallSheetSize.onboarding.width == 520)
        #expect(KikiPaywallSheetSize.onboarding.height == 520)
    }

    @Test("Paywall plan stores display metadata")
    func paywallPlanStoresDisplayMetadata() {
        let plan = KikiPaywallPlan(
            id: "lifetime",
            title: "Lifetime",
            displayPrice: "$10.99",
            originalPrice: "$14.99",
            billingDetail: "once",
            badge: "Best Value",
            isAvailable: true
        )

        #expect(plan.id == "lifetime")
        #expect(plan.badge == "Best Value")
        #expect(plan.originalPrice == "$14.99")
        #expect(plan.isAvailable)
    }

    @Test("Paywall stats derive stable value identity")
    func paywallStatsUseStableIdentity() {
        let first = KikiPaywallStatConfig(value: "3", label: "kits")
        let second = KikiPaywallStatConfig(value: "3", label: "kits")
        let explicit = KikiPaywallStatConfig(id: "custom", value: "3", label: "kits")

        #expect(first == second)
        #expect(first.id == second.id)
        #expect(explicit.id == "custom")
        #expect(explicit != first)
    }

    @MainActor
    @Test("Paywall shell and header are constructible")
    func paywallShellAndHeaderAreConstructible() {
        let shell = KikiPaywallShell {
            KikiPaywallHeader(
                title: "Choose your plan",
                subtitle: "Unlock the full app."
            )
        } content: {
            KikiPaywallFeatureRow(icon: "checkmark.circle", text: "Reusable shell")
        } actions: {
            KikiPaywallActionLabel(
                title: "Unlock",
                isLoading: false
            )
        } footer: {
            Text("Terms")
        }

        _ = shell.body
    }

    @MainActor
    @Test("Paywall sheet preset is constructible")
    func paywallSheetPresetIsConstructible() {
        let plans = [
            KikiPaywallPlan(
                id: "lifetime",
                title: "Lifetime",
                displayPrice: "$12.99",
                billingDetail: "one-time purchase"
            )
        ]

        let sheet = KikiPaywallSheet(
            header: .init(title: "Upgrade", subtitle: "Unlock everything"),
            stats: [.init(value: "3", label: "kits")],
            features: ["Reusable shell", "Paywall preset"],
            plans: plans,
            selectedPlanID: .constant("lifetime"),
            primary: .init(title: "Unlock") {},
            secondaryActions: [.init(title: "Restore") {}],
            size: .compact
        )

        _ = sheet.body
    }

    @Test("Paywall action config defaults to bordered style")
    func paywallActionConfigDefaultsToBorderedStyle() {
        let bordered = KikiPaywallActionConfig(title: "Buy") {}
        let link = KikiPaywallActionConfig(title: "Restore", style: .footerLink) {}

        #expect(bordered.style == .bordered)
        #expect(link.style == .footerLink)
    }

    @MainActor
    @Test("Paywall sheet accepts mixed bordered and footer-link secondaries")
    func paywallSheetAcceptsMixedSecondaryStyles() {
        let plans = [
            KikiPaywallPlan(
                id: "lifetime",
                title: "Lifetime",
                displayPrice: "$12.99",
                billingDetail: "one-time purchase"
            )
        ]

        let sheet = KikiPaywallSheet(
            header: .init(title: "Upgrade", subtitle: "Unlock everything"),
            plans: plans,
            selectedPlanID: .constant("lifetime"),
            primary: .init(title: "Unlock") {},
            secondaryActions: [
                .init(title: "Start Free Trial") {},
                .init(title: "Restore Purchases", style: .footerLink) {}
            ]
        )

        _ = sheet.body
    }

    @Test("Paywall action presentation carries style through")
    func paywallActionPresentationCarriesStyleThrough() {
        let restore = KikiPaywallActionPresentation(
            title: "Restore",
            style: .footerLink,
            action: {}
        )

        #expect(restore.style == .footerLink)
    }

    @MainActor
    @Test("Paywall link action button is constructible from config")
    func paywallLinkActionButtonIsConstructible() {
        let config = KikiPaywallActionConfig(
            title: "Restore",
            style: .footerLink,
            action: {}
        )
        let button = KikiPaywallLinkActionButton(action: config)

        _ = button.body
    }

    @MainActor
    @Test("Paywall status card primitives are constructible")
    func paywallStatusCardPrimitivesAreConstructible() {
        let plan = KikiPaywallPlan(
            id: "supporter",
            title: "Supporter Lifetime",
            displayPrice: "$10.99",
            billingDetail: "one-time purchase",
            badge: "Recommended",
            isAvailable: true
        )

        _ = VStack {
            KikiPaywallStatusHeader(
                title: "Pro",
                subtitle: "All features are unlocked.",
                systemName: "checkmark.seal.fill"
            ) {
                KikiPaywallPill(text: "Lifetime")
            }

            KikiPaywallPlanRow(
                plan: plan,
                isSelected: true,
                priceSuffix: "once",
                onSelect: {}
            )

            KikiPaywallMessage("Purchase restored.", tone: .success)
            KikiPaywallMetadataRow(title: "Status", value: "Active")
            KikiPaywallDotSeparator()
        }
        .kikiPaywallCard()
    }

    @MainActor
    @Test("Paywall window controller is constructible")
    func paywallWindowControllerIsConstructible() {
        let controller = KikiPaywallWindowController(title: "Upgrade") {
            KikiPaywallShell {
                KikiPaywallHeader(
                    title: "Choose your plan",
                    subtitle: "Unlock the full app."
                )
            } content: {
                KikiPaywallFeatureRow(icon: "checkmark.circle", text: "Standalone window")
            }
        }

        #expect(!controller.isVisible)
    }
}
