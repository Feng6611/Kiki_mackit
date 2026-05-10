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
}
