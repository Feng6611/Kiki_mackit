import KikiSettings
import SwiftUI
import Testing

struct KikiSettingsTests {
    enum Tab: Hashable {
        case general
        case about
    }

    @MainActor
    @Test("Navigation model stores selected tab")
    func navigationModelStoresSelectedTab() {
        let model = KikiSettingsNavigationModel<Tab>(selectedTab: .general)
        #expect(model.selectedTab == .general)

        model.selectedTab = .about
        #expect(model.selectedTab == .about)
    }

    @Test("Tab spec exposes tab as stable id")
    func tabSpecUsesTabAsID() {
        let spec = KikiSettingsTabSpec(Tab.general, title: "General", systemImage: "gearshape")

        #expect(spec.id == .general)
        #expect(spec.title == "General")
        #expect(spec.systemImage == "gearshape")
    }

    @MainActor
    @Test("Settings shell and rows are constructible")
    func settingsShellAndRowsAreConstructible() {
        let tabs = [
            KikiSettingsTabSpec(Tab.general, title: "General", systemImage: "gearshape"),
            KikiSettingsTabSpec(Tab.about, title: "About", systemImage: "info.circle"),
        ]

        _ = KikiSettingsShell(selection: .constant(Tab.general), tabs: tabs) { tab in
            switch tab {
            case .general:
                KikiSettingsPane {
                    Section("Status") {
                        KikiSettingsStatusRow(
                            title: "Summary",
                            value: "Ready",
                            systemImage: "checkmark.circle"
                        )
                        KikiSettingsHelperText("Helper copy.")
                    }
                }
            case .about:
                KikiAboutPane(appName: "Test App", versionText: "Version 1") {
                    KikiSettingsStatusRow(
                        title: "Status",
                        value: "Direct version",
                        systemImage: "heart.circle"
                    )
                } links: {
                    KikiSettingsLinkRow(
                        title: "Website",
                        value: "example.com",
                        urlString: "https://example.com",
                        systemImage: "globe"
                    )
                    KikiSettingsCopyRow(
                        title: "Bundle ID",
                        value: "com.example.test",
                        systemImage: "number"
                    )
                }
            }
        }
    }
}
