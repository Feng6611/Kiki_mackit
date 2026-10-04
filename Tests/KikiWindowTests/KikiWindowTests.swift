import AppKit
import KikiWindow
import SwiftUI
import Testing

struct KikiWindowTests {
    @Test("Window configuration stores AppKit chrome settings")
    func windowConfigurationStoresChromeSettings() {
        let configuration = KikiWindowConfiguration.transparentUtility(
            title: "Welcome",
            size: CGSize(width: 480, height: 360),
            minimumSize: CGSize(width: 320, height: 240),
            frameAutosaveName: "KikiWindowTests.Welcome",
            hiddenButtons: .all
        )

        #expect(configuration.title == "Welcome")
        #expect(configuration.size == CGSize(width: 480, height: 360))
        #expect(configuration.minimumSize == CGSize(width: 320, height: 240))
        #expect(configuration.frameAutosaveName == "KikiWindowTests.Welcome")
        #expect(configuration.styleMask == [.borderless])
        #expect(configuration.titlebarAppearsTransparent)
        #expect(configuration.titleVisibility == .hidden)
        #expect(configuration.isMovableByWindowBackground)
        #expect(configuration.backgroundColor == .clear)
        #expect(configuration.contentCornerRadius == 20)
        #expect(configuration.hiddenButtons == .all)
    }

    @MainActor
    @Test("Transparent background and single window controller are constructible")
    func transparentBackgroundAndSingleWindowControllerAreConstructible() {
        let transparentBackground = Text("Window")
            .kikiTransparentWindowBackground(
                isMovableByWindowBackground: true,
                frameAutosaveName: "KikiWindowTests.Transparent"
            )

        let controller = KikiSingleWindowController(
            configuration: .utility(
                title: "Utility",
                size: CGSize(width: 320, height: 240)
            )
        ) {
            Text("Utility")
        }

        _ = transparentBackground
        #expect(!controller.isVisible)
    }

    @MainActor
    @Test("Desktop glass window background is constructible")
    func desktopGlassWindowBackgroundIsConstructible() {
        let glass = Text("Window")
            .kikiDesktopGlassWindowBackground(
                tint: .blue,
                tintOpacity: 0.12,
                isMovableByWindowBackground: true
            )

        let bridge = KikiDesktopGlassWindowBackground(tint: .blue, tintOpacity: 0.12)

        _ = glass
        _ = bridge
    }

    @MainActor
    @Test("Transparent utility applies rounded non-opaque content at runtime")
    func transparentUtilityAppliesRoundedContentAtRuntime() {
        let controller = KikiSingleWindowController(
            configuration: .transparentUtility(
                title: "Rounded Welcome",
                size: CGSize(width: 320, height: 240)
            )
        ) {
            Color.clear
        }

        controller.show()
        defer { controller.close() }

        #expect(controller.window?.isOpaque == false)
        #expect(controller.window?.styleMask == [.borderless])
        #expect(controller.window?.contentView?.layer?.cornerRadius == 20)
        #expect(controller.window?.contentView?.layer?.masksToBounds == true)
    }

    @MainActor
    @Test("Transparent utility repairs its clip when a sheet starts")
    func transparentUtilityRepairsItsClipWhenSheetStarts() {
        let controller = KikiSingleWindowController(
            configuration: .transparentUtility(
                title: "Rounded Welcome",
                size: CGSize(width: 320, height: 240)
            )
        ) {
            Color.clear
        }

        controller.show()
        defer { controller.close() }

        controller.window?.contentView?.layer?.cornerRadius = 0
        controller.windowWillBeginSheet(
            Notification(name: Notification.Name("KikiWindowTests.sheet"))
        )

        #expect(controller.window?.contentView?.layer?.cornerRadius == 20)
        #expect(controller.window?.contentView?.layer?.masksToBounds == true)
    }

    @MainActor
    @Test("First show centers a window whose autosave name has no stored frame")
    func firstShowCentersWhenAutosaveFrameIsMissing() throws {
        let screen = try #require(NSScreen.main)
        for name in ["KikiWindowTests.FreshFrame", ""] {
            UserDefaults.standard.removeObject(forKey: "NSWindow Frame \(name)")
            let controller = KikiSingleWindowController(
                configuration: .utility(
                    title: "Fresh",
                    size: CGSize(width: 300, height: 200),
                    frameAutosaveName: name
                )
            ) {
                Text("Fresh").frame(width: 300, height: 200)
            }
            controller.show()
            let window = try #require(controller.window)
            defer { controller.close() }

            #expect(abs(window.frame.midX - screen.visibleFrame.midX) < 1)
        }
    }
}
