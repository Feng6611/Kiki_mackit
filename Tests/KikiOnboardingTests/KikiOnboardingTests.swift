import KikiAuthorization
import KikiOnboarding
import SwiftUI
import Testing

struct KikiOnboardingTests {
    @Test("Default onboarding window keeps compact welcome geometry")
    func defaultWindowKeepsCompactWelcomeGeometry() {
        #expect(KikiOnboardingDefaults.windowSize.width == 560)
        #expect(KikiOnboardingDefaults.windowSize.height == 520)
        #expect(KikiOnboardingDefaults.primaryActionWidth == 200)
    }

    @Test("Onboarding rows derive stable value identity")
    func onboardingRowsUseStableIdentity() {
        let first = KikiOnboardingRow(
            systemImage: "sparkles",
            title: "Fast setup",
            detail: "Use the default flow."
        )
        let second = KikiOnboardingRow(
            systemImage: "sparkles",
            title: "Fast setup",
            detail: "Use the default flow."
        )
        let explicitID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let explicit = KikiOnboardingRow(
            id: explicitID,
            systemImage: "sparkles",
            title: "Fast setup",
            detail: "Use the default flow."
        )

        #expect(first == second)
        #expect(first.id == second.id)
        #expect(explicit.id == explicitID)
    }

    @MainActor
    @Test("Coordinator advances and returns whole onboarding pages")
    func coordinatorAdvancesAndReturnsWholePages() {
        let configuration = KikiOnboardingConfiguration(
            appName: "Test App",
            steps: [
                .custom(id: "first") { _ in AnyView(Text("First")) },
                .custom(id: "second") { _ in AnyView(Text("Second")) }
            ],
            completionKey: "KikiOnboardingTests.page-transition"
        )
        let coordinator = KikiOnboardingCoordinator(configuration: configuration)

        #expect(coordinator.currentStep?.id == "custom.first")
        coordinator.advance()
        #expect(coordinator.currentStep?.id == "custom.second")
        coordinator.back()
        #expect(coordinator.currentStep?.id == "custom.first")
    }

    @MainActor
    @Test("Onboarding scaffold and window controller are constructible")
    func onboardingScaffoldAndWindowControllerAreConstructible() {
        let scaffold = KikiOnboardingScaffold(
            appName: "Test App",
            title: "Welcome to Test App",
            bodyText: "Set up the app in a minute.",
            appIcon: nil,
            rows: [
                .init(systemImage: "sparkles", title: "Fast setup", detail: "Use the default starter flow."),
                .init(systemImage: "gearshape", title: "Simple settings", detail: "Keep product logic outside Kiki.")
            ],
            permissionRow: KikiOnboardingPermissionRow(
                panel: .accessibility,
                instruction: "Enable Accessibility so the app can respond to input."
            ),
            primaryAction: .init(title: "Continue") {},
            secondaryAction: .init(title: "Later") {}
        )

        let controller = KikiOnboardingWindowController {
            scaffold
        }

        _ = scaffold.body
        #expect(!controller.isVisible)
    }

    @MainActor
    @Test("Scaffold renders custom content with back/skip navigation actions")
    func scaffoldRendersCustomContentWithNavigationActions() {
        let scaffold = KikiOnboardingScaffold(
            appName: "Test App",
            title: "Set up permissions",
            bodyText: "Grant access to continue.",
            primaryAction: .init(title: "Continue") {},
            backAction: .init(title: "Back") {},
            skipAction: .init(title: "Skip for now") {},
            stepIndex: 1,
            stepCount: 3
        ) {
            Text("Product-specific step body")
        }

        _ = scaffold.body
    }

    @MainActor
    @Test("Scaffold can present an event-driven step without a primary button")
    func scaffoldSupportsEventDrivenStepWithoutPrimaryButton() {
        let scaffold = KikiOnboardingScaffold(
            appName: "Test App",
            title: "Move to the corner",
            bodyText: "The next step starts automatically.",
            primaryAction: nil,
            skipAction: .init(title: "Set Up Later") {}
        ) {
            Text("Waiting for a system event")
        }

        _ = scaffold.body
    }

    @MainActor
    @Test("Status row supports tone, action, loading, and trust note")
    func statusRowSupportsStatePresentation() {
        var actionCount = 0
        let row = KikiOnboardingStatusRow(
            systemImage: "arrow.down.circle",
            title: "Import",
            detail: "Bring in an existing library when you are ready.",
            statusLabel: "Not started",
            tone: .neutral,
            action: .init(title: "Import now") { actionCount += 1 },
            trustNote: "Your existing files stay on this Mac.",
            tint: .accentColor
        )
        let loadingRow = KikiOnboardingStatusRow(
            systemImage: "arrow.triangle.2.circlepath",
            title: "Checking",
            detail: "Looking for an available source.",
            isLoading: true
        )

        _ = row.body
        _ = loadingRow.body
        #expect(actionCount == 0)
    }

    @MainActor
    @Test("Rows initializer accepts back and skip actions")
    func rowsInitializerAcceptsBackAndSkipActions() {
        let scaffold = KikiOnboardingScaffold(
            appName: "Test App",
            title: "Features",
            rows: [
                .init(systemImage: "sparkles", title: "Fast setup", detail: "Use the default starter flow.")
            ],
            primaryAction: .init(title: "Continue") {},
            backAction: .init(title: "Back") {},
            skipAction: .init(title: "Skip") {},
            stepIndex: 0,
            stepCount: 2
        )

        _ = scaffold.body
    }
}
