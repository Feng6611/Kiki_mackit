import KikiPaywall
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
}
