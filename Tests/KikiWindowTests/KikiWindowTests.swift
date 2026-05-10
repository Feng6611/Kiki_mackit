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
        #expect(configuration.styleMask.contains(.fullSizeContentView))
        #expect(configuration.titlebarAppearsTransparent)
        #expect(configuration.titleVisibility == .hidden)
        #expect(configuration.isMovableByWindowBackground)
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
}
