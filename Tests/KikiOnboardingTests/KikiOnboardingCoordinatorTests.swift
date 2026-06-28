import KikiOnboarding
import SwiftUI
import Testing

@MainActor
struct KikiOnboardingCoordinatorTests {
    private func makeConfiguration(includePaywall: Bool = false) -> KikiOnboardingConfiguration {
        var steps: [KikiOnboardingStep] = [
            .welcome(KikiOnboardingWelcomeContent(title: "Welcome", continueTitle: "Continue")),
            .features(KikiOnboardingFeatureContent(title: "Features", rows: [])),
        ]
        if includePaywall {
            steps.append(.paywallHandoff)
        }
        steps.append(.success(KikiOnboardingSuccessContent(title: "Done")))
        return KikiOnboardingConfiguration(
            appName: "Test",
            steps: steps,
            completionKey: "kiki.onboarding.tests"
        )
    }

    @Test("Coordinator starts at step zero and advances")
    func coordinatorAdvancesAndBacks() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let coordinator = KikiOnboardingCoordinator(
            configuration: makeConfiguration(),
            completionStore: store
        )

        #expect(coordinator.currentStepIndex == 0)
        coordinator.advance()
        #expect(coordinator.currentStepIndex == 1)
        coordinator.back()
        #expect(coordinator.currentStepIndex == 0)
        #expect(coordinator.canGoBack == false)
    }

    @Test("Finish marks completion in the store")
    func finishMarksCompletion() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let config = makeConfiguration()
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store
        )
        coordinator.finish()
        #expect(store.isCompleted(forKey: config.completionKey))

        coordinator.resetCompletion()
        #expect(store.isCompleted(forKey: config.completionKey) == false)
    }

    @Test("Advancing past the last step calls onFinished and marks completion")
    func advanceFromLastStepFinishes() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let config = makeConfiguration()
        var finishedCount = 0
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store,
            onFinished: { finishedCount += 1 }
        )

        coordinator.advance()
        coordinator.advance()
        coordinator.advance()

        #expect(finishedCount == 1)
        #expect(store.isCompleted(forKey: config.completionKey))
    }

    @Test("Paywall handoff invokes callback instead of auto-advancing")
    func paywallHandoffInvokesCallback() {
        let store = KikiOnboardingInMemoryCompletionStore()
        var handoffCount = 0
        let coordinator = KikiOnboardingCoordinator(
            configuration: makeConfiguration(includePaywall: true),
            completionStore: store,
            onPaywallHandoff: { handoffCount += 1 }
        )

        coordinator.advance()
        coordinator.advance()

        #expect(handoffCount == 1)
        #expect(coordinator.currentStepIndex == 2)
    }

    @Test("Paywall handoff auto-advances when no callback is provided")
    func paywallHandoffAutoAdvancesWithoutCallback() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let coordinator = KikiOnboardingCoordinator(
            configuration: makeConfiguration(includePaywall: true),
            completionStore: store
        )

        coordinator.advance()
        coordinator.advance()

        #expect(coordinator.currentStepIndex == 3)
    }

    @Test("Step id reflects step kind")
    func stepIDReflectsCase() {
        #expect(KikiOnboardingStep.welcome(KikiOnboardingWelcomeContent(title: "t")).id == "welcome")
        #expect(KikiOnboardingStep.paywallHandoff.id == "paywallHandoff")
        #expect(KikiOnboardingStep.custom(id: "demo", view: { AnyView(EmptyView()) }).id == "custom.demo")
    }
}
