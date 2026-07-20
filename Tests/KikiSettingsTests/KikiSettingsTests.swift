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

    @Test("Settings defaults bound adaptation around the ideal window size")
    func settingsDefaultsAllowPaneAdaptation() {
        #expect(KikiSettingsDefaults.windowHeight > KikiSettingsDefaults.minimumWindowHeight)
        #expect(KikiSettingsDefaults.maximumWindowHeight > KikiSettingsDefaults.windowHeight)
        #expect(KikiSettingsDefaults.minimumWindowWidth == KikiSettingsDefaults.windowWidth)
        #expect(KikiSettingsDefaults.maximumWindowWidth > KikiSettingsDefaults.windowWidth)
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
                            value: "Ready"
                        )
                        KikiSettingsStatusRow(
                            title: "Pro status",
                            value: "Lifetime Pro",
                            systemImage: "checkmark.seal",
                            tone: .accent,
                            trailingSystemImage: "chevron.right",
                            action: {}
                        )
                        KikiAuthorizationStatusRow(
                            title: "Accessibility",
                            isAuthorized: false,
                            unauthorizedValue: "Needs permission",
                            action: {}
                        )
                        KikiAuthorizationStatusRow(
                            title: "Accessibility",
                            isAuthorized: true
                        )
                        KikiAuthorizationStatusRow(
                            title: "Debug accessibility",
                            isAuthorized: true,
                            allowsAuthorizedAction: true,
                            action: {}
                        )
                        KikiSettingsToggleRow("Enabled", isOn: .constant(true))
                        KikiSettingsSegmentedPickerRow(
                            "Mode",
                            selection: .constant(2),
                            options: [1, 2, 3],
                            leadingCaption: "Low",
                            trailingCaption: "High",
                            optionTitle: { "\($0)" }
                        )
                        KikiSettingsMenuPickerRow(
                            "Preset",
                            selection: .constant(2),
                            options: [1, 2, 3, 4],
                            optionTitle: { "Preset \($0)" }
                        )
                        KikiSettingsStepperRow(
                            "Limit",
                            value: .constant(10),
                            in: 1...60,
                            valueText: { "\($0) min" }
                        )
                        KikiSettingsSliderRow(
                            "Intensity",
                            value: .constant(0.65),
                            in: 0...1,
                            step: 0.05,
                            valueText: { "\(Int(($0 * 100).rounded()))%" }
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
    @Test("Segmented picker row accepts all layout preferences")
    func segmentedPickerRowAcceptsAllLayoutPreferences() {
        _ = KikiSettingsSegmentedPickerRow(
            "Duration",
            selection: .constant(10),
            options: [5, 10, 30, 60],
            optionTitle: { "\($0) min" }
        )
        _ = KikiSettingsSegmentedPickerRow(
            "Strength",
            selection: .constant(3),
            options: [1, 2, 3, 4, 5],
            leadingCaption: "Subtle",
            trailingCaption: "Strong",
            preferredStyle: .adaptive,
            optionTitle: { "\($0)" }
        )
        _ = KikiSettingsSegmentedPickerRow(
            "Preset",
            selection: .constant("b"),
            options: ["a", "b", "c"],
            preferredStyle: .segmented,
            optionTitle: { $0.uppercased() }
        )
        _ = KikiSettingsSegmentedPickerRow(
            "Preset",
            selection: .constant("b"),
            options: ["a", "b", "c"],
            preferredStyle: .menu,
            optionTitle: { $0.uppercased() }
        )
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
