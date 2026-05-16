import AppKit
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

    @MainActor
    @Test("Settings opener performs standard settings item from the main menu")
    func settingsOpenerPerformsStandardSettingsItemFromMainMenu() {
        let application = NSApplication.shared
        let originalMainMenu = application.mainMenu
        defer {
            application.mainMenu = originalMainMenu
        }

        var disabledPerformCount = 0
        let disabledTarget = SettingsMenuTarget {
            disabledPerformCount += 1
        }

        var performCount = 0
        let target = SettingsMenuTarget {
            performCount += 1
        }

        let mainMenu = NSMenu(title: "Main")
        mainMenu.autoenablesItems = false

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "App")
        appMenu.autoenablesItems = false

        let disabledSettingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(SettingsMenuTarget.performSettingsAction),
            keyEquivalent: ","
        )
        disabledSettingsItem.target = disabledTarget
        disabledSettingsItem.isEnabled = false

        let settingsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(SettingsMenuTarget.performSettingsAction),
            keyEquivalent: ""
        )
        settingsItem.target = target
        settingsItem.isEnabled = true

        appMenu.addItem(disabledSettingsItem)
        appMenu.addItem(settingsItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        application.mainMenu = mainMenu

        KikiSettingsOpener().open(preparesWindow: false)

        #expect(disabledPerformCount == 0)
        #expect(performCount == 1)
    }
}

@MainActor
private final class SettingsMenuTarget: NSObject {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc func performSettingsAction() {
        action()
    }
}
