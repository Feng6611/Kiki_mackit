import AppKit
import KikiMenuBar
import SwiftUI
import Testing

struct KikiMenuBarTests {
    @MainActor
    @Test("Menu item metadata is exposed for adapters")
    func menuItemMetadata() {
        let action = KikiMenuItem.action(title: "Settings", isEnabled: true) {}
        let disabledToggle = KikiMenuItem.toggle(title: "Enable", isOn: false, isEnabled: false) {}
        let link = KikiMenuItem.link(title: "Official", urlString: "https://example.com")
        let status = KikiMenuItem.status(title: "Ready")

        #expect(action.title == "Settings")
        #expect(action.isEnabled)
        #expect(disabledToggle.title == "Enable")
        #expect(!disabledToggle.isEnabled)
        #expect(link.title == "Official")
        #expect(link.isEnabled)
        #expect(status.title == "Ready")
        #expect(!status.isEnabled)
        #expect(KikiMenuItem.separator.title == nil)
    }

    @Test("Standard shortcuts map to macOS defaults")
    func standardShortcuts() {
        #expect(KikiMenuShortcut.settings.key == ",")
        #expect(KikiMenuShortcut.settings.modifiers == .command)
        #expect(KikiMenuShortcut.quit.key == "q")
        #expect(KikiMenuShortcut.quit.modifiers == .command)
    }

    @MainActor
    @Test("Convenience items build expected menu metadata")
    func convenienceItemsBuildExpectedMenuMetadata() throws {
        let menu = KikiMenuBuilder.menu(
            from: [
                .settings {},
                .quit(appName: "Kiki Test") {},
                .link(title: "Docs", urlString: "https://example.com"),
                .status(title: "Ready")
            ],
            title: "Kiki Test"
        )
        let settings = try #require(menu.item(at: 0))
        let quit = try #require(menu.item(at: 1))
        let link = try #require(menu.item(at: 2))
        let status = try #require(menu.item(at: 3))

        #expect(settings.title == "Settings...")
        #expect(settings.keyEquivalent == ",")
        #expect(settings.keyEquivalentModifierMask == .command)
        #expect(settings.isEnabled)

        #expect(quit.title == "Quit Kiki Test")
        #expect(quit.keyEquivalent == "q")
        #expect(quit.keyEquivalentModifierMask == .command)
        #expect(quit.isEnabled)

        #expect(link.title == "Docs")
        #expect(link.isEnabled)

        #expect(status.title == "Ready")
        #expect(!status.isEnabled)
    }

    @MainActor
    @Test("Toggle items map state and enabled flags into NSMenuItems")
    func toggleItemsMapStateAndEnabledFlagsIntoMenuItems() throws {
        let controller = KikiMenuBarController(title: "Kiki Test") {
            [
                .toggle(title: "Enabled Feature", isOn: true, isEnabled: true) {},
                .toggle(title: "Disabled Feature", isOn: false, isEnabled: false) {}
            ]
        }

        let menu = controller.makeMenu()
        let enabled = try #require(menu.item(at: 0))
        let disabled = try #require(menu.item(at: 1))

        #expect(enabled.state == .on)
        #expect(enabled.isEnabled)
        #expect(disabled.state == .off)
        #expect(!disabled.isEnabled)
    }

    @MainActor
    @Test("Status button active state is updateable")
    func statusButtonActiveStateIsUpdateable() {
        let controller = KikiMenuBarController(
            title: "Kiki Test",
            systemImageName: "keyboard"
        ) {
            [.status(title: "Ready")]
        }

        controller.updateButtonState(isActive: true)
        controller.updateButtonTint(.systemOrange)
        controller.updateButtonState(isActive: false)
        controller.updateButtonTint(nil)
        controller.updateButtonTooltip("Kiki Test: ready")
    }

    @MainActor
    @Test("Built menu retains action targets after rebuilding")
    func builtMenuRetainsActionTargetsAfterRebuilding() throws {
        var performCount = 0
        let controller = KikiMenuBarController(title: "Kiki Test") {
            [
                .action(title: "Run") {
                    performCount += 1
                }
            ]
        }

        let firstMenu = controller.makeMenu()
        _ = controller.makeMenu()

        let item = try #require(firstMenu.item(at: 0))
        let action = try #require(item.action)

        #expect(NSApp.sendAction(action, to: item.target, from: item))
        #expect(performCount == 1)
    }

    @MainActor
    @Test("Popover controller is constructible with SwiftUI content")
    func popoverControllerIsConstructible() {
        let controller = KikiMenuBarPopoverController(
            title: "Kiki Test",
            systemImageName: "bolt",
            popoverSize: CGSize(width: 240, height: 180)
        ) {
            Text("Ready")
        }

        #expect(!controller.isShown)
    }
}
