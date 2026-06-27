import KikiAuthorization
import KikiOnboarding
import SwiftUI
import Testing

struct KikiOnboardingTests {
    @MainActor
    @Test("Onboarding scaffold and window controller are constructible")
    func onboardingScaffoldAndWindowControllerAreConstructible() {
        let scaffold = KikiOnboardingScaffold(
            appName: "Test App",
            title: "Welcome to Test App",
            bodyText: "Set up the app in a minute.",
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
}
