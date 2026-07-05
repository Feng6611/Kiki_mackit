@testable import KikiSettings
import Testing

@MainActor
struct KikiSettingsCoordinatorTests {
    enum Tab: Hashable {
        case general
        case about
    }

    private func makeTabs() -> [KikiSettingsTabSpec<Tab>] {
        [
            KikiSettingsTabSpec(.general, title: "General", systemImage: "gearshape"),
            KikiSettingsTabSpec(.about, title: "About", systemImage: "info.circle"),
        ]
    }

    @Test("Coordinator exposes initial tab and updates selection")
    func coordinatorStoresInitialTab() {
        let coordinator = KikiSettingsCoordinator<Tab>(
            tabs: makeTabs(),
            initialTab: .general
        )
        #expect(coordinator.navigation.selectedTab == .general)
        coordinator.select(.about)
        #expect(coordinator.navigation.selectedTab == .about)
    }

    @Test("open(tab:) updates selection before opening")
    func openWithTabUpdatesSelection() {
        let coordinator = KikiSettingsCoordinator<Tab>(
            tabs: makeTabs(),
            initialTab: .general
        )
        coordinator.open(tab: .about, isMenuBarApp: false)
        #expect(coordinator.navigation.selectedTab == .about)
    }

    @Test("isVisible is false when no window controller is attached")
    func isVisibleIsFalseWithoutWindowController() {
        let coordinator = KikiSettingsCoordinator<Tab>(
            tabs: makeTabs(),
            initialTab: .general
        )
        #expect(coordinator.isVisible == false)
    }

    @Test("close() is a no-op when no window controller is attached")
    func closeIsNoOpWithoutWindowController() {
        let coordinator = KikiSettingsCoordinator<Tab>(
            tabs: makeTabs(),
            initialTab: .general
        )
        coordinator.close()
        #expect(coordinator.isVisible == false)
    }

    @Test("Coordinator view is constructible from coordinator")
    func coordinatorViewIsConstructible() {
        let coordinator = KikiSettingsCoordinator<Tab>(
            tabs: makeTabs(),
            initialTab: .general
        )
        _ = KikiSettingsCoordinatorView(coordinator: coordinator) { tab in
            switch tab {
            case .general:
                KikiSettingsPane { }
            case .about:
                KikiAboutPane(appName: "Test", versionText: "1.0") { } links: { }
            }
        }
    }
}
