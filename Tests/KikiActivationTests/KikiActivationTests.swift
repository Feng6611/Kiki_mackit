import AppKit
import KikiActivation
import Testing

struct KikiActivationTests {
    @MainActor
    @Test("Activation coordinator is constructible and start is idempotent")
    func activationCoordinatorIsConstructibleAndStartIsIdempotent() {
        let coordinator = KikiActivationPolicyCoordinator(
            prewarmsThroughDockOnFirstActivation: true
        )

        coordinator.start()
        coordinator.start()
        coordinator.reset(toPolicy: .accessory, reason: "test")
    }
}
