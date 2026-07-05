@testable import KikiOnboarding
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

    @Test("back() re-fires paywallHandoff when stepping back into it")
    func backIntoPaywallHandoffRefires() {
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

        coordinator.advance()
        coordinator.back()
        #expect(coordinator.currentStepIndex == 2)
        #expect(handoffCount == 2)
    }

    @Test("Step id reflects step kind")
    func stepIDReflectsCase() {
        #expect(KikiOnboardingStep.welcome(KikiOnboardingWelcomeContent(title: "t")).id == "welcome")
        #expect(KikiOnboardingStep.paywallHandoff.id == "paywallHandoff")
        #expect(KikiOnboardingStep.custom(id: "demo", view: { _ in AnyView(EmptyView()) }).id == "custom.demo")
    }

    @Test("skip() finishes when canSkip is true")
    func skipFinishesWhenAllowed() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let config = KikiOnboardingConfiguration(
            appName: "Test",
            steps: [
                .welcome(KikiOnboardingWelcomeContent(title: "Welcome", continueTitle: "Continue")),
                .success(KikiOnboardingSuccessContent(title: "Done"))
            ],
            completionKey: "kiki.onboarding.tests.skip",
            canSkip: true
        )
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store
        )

        #expect(coordinator.canSkip == true)
        coordinator.skip()

        #expect(store.isCompleted(forKey: config.completionKey))
        #expect(coordinator.currentStepIndex == 0)
    }

    @Test("skip() is a no-op when canSkip is false")
    func skipIsNoOpWhenDisallowed() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let config = KikiOnboardingConfiguration(
            appName: "Test",
            steps: [
                .welcome(KikiOnboardingWelcomeContent(title: "Welcome", continueTitle: "Continue")),
                .success(KikiOnboardingSuccessContent(title: "Done"))
            ],
            completionKey: "kiki.onboarding.tests.noskip",
            canSkip: false
        )
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store
        )

        #expect(coordinator.canSkip == false)
        coordinator.skip()

        #expect(store.isCompleted(forKey: config.completionKey) == false)
    }

    @Test("Window close can complete onboarding exactly once")
    func windowCloseCompletesWhenConfigured() {
        let store = KikiOnboardingInMemoryCompletionStore()
        var finishedCount = 0
        let config = KikiOnboardingConfiguration(
            appName: "Test",
            steps: [
                .welcome(KikiOnboardingWelcomeContent(title: "Welcome"))
            ],
            completionKey: "kiki.onboarding.tests.close",
            closeDisposition: .complete
        )
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store,
            onFinished: { finishedCount += 1 }
        )

        coordinator.handleWindowClosed()
        coordinator.finish()

        #expect(store.isCompleted(forKey: config.completionKey))
        #expect(finishedCount == 1)
    }

    @Test("Window close keeps onboarding pending by default")
    func windowCloseKeepsPendingByDefault() {
        let store = KikiOnboardingInMemoryCompletionStore()
        let config = makeConfiguration()
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store
        )

        coordinator.handleWindowClosed()

        #expect(store.isCompleted(forKey: config.completionKey) == false)
    }

    @Test("Configuration preserves custom window geometry")
    func configurationPreservesWindowGeometry() {
        let size = CGSize(width: 620, height: 660)
        let config = KikiOnboardingConfiguration(
            appName: "Test",
            steps: [],
            completionKey: "kiki.onboarding.tests.geometry",
            windowSize: size,
            minimumWindowSize: CGSize(width: 560, height: 560)
        )

        #expect(config.windowSize == size)
        #expect(config.minimumWindowSize == CGSize(width: 560, height: 560))
    }

    @Test("An empty flow completes without presenting a window")
    func emptyFlowCompletesWithoutWindow() {
        let store = KikiOnboardingInMemoryCompletionStore()
        var finishedCount = 0
        let config = KikiOnboardingConfiguration(
            appName: "Test",
            steps: [],
            completionKey: "kiki.onboarding.tests.empty"
        )
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store,
            onFinished: { finishedCount += 1 }
        )

        coordinator.start()

        #expect(store.isCompleted(forKey: config.completionKey))
        #expect(coordinator.isVisible == false)
        #expect(finishedCount == 1)
    }

    @Test("custom step receives a working navigation struct")
    func customStepNavigationAdvances() {
        let store = KikiOnboardingInMemoryCompletionStore()
        var captured: KikiOnboardingNavigation?
        let config = KikiOnboardingConfiguration(
            appName: "Test",
            steps: [
                .custom(id: "demo", view: { nav in
                    captured = nav
                    return AnyView(EmptyView())
                }),
                .success(KikiOnboardingSuccessContent(title: "Done"))
            ],
            completionKey: "kiki.onboarding.tests.custom"
        )
        let coordinator = KikiOnboardingCoordinator(
            configuration: config,
            completionStore: store
        )

        coordinator.start()
        guard let nav = captured else {
            Issue.record("custom view builder was not invoked with navigation")
            return
        }

        nav.advance()
        #expect(coordinator.currentStepIndex == 1)

        nav.back()
        #expect(coordinator.currentStepIndex == 0)

        nav.skip()
        #expect(store.isCompleted(forKey: config.completionKey) == false)

        nav.finish()
        #expect(store.isCompleted(forKey: config.completionKey))
    }
}
