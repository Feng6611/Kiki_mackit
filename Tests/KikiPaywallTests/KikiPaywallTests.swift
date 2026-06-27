import KikiPaywall
import SwiftUI
import Testing

struct KikiPaywallTests {
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
                isLoading: false,
                isProminent: true
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
            secondary: .init(title: "Restore") {}
        )

        _ = sheet.body
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
