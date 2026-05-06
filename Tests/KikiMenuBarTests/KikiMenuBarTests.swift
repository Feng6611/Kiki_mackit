import AppKit
import KikiMenuBar
import Testing

struct KikiMenuBarTests {
    @MainActor
    @Test("Menu item metadata is exposed for adapters")
    func menuItemMetadata() {
        let action = KikiMenuItem.action(title: "Settings", isEnabled: true) {}
        let disabledToggle = KikiMenuItem.toggle(title: "Enable", isOn: false, isEnabled: false) {}

        #expect(action.title == "Settings")
        #expect(action.isEnabled)
        #expect(disabledToggle.title == "Enable")
        #expect(!disabledToggle.isEnabled)
        #expect(KikiMenuItem.separator.title == nil)
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
}
