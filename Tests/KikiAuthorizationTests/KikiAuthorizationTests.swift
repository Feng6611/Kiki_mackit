import AppKit
import KikiAuthorization
import Testing

struct KikiAuthorizationTests {
    @Test("Authorization panels expose stable System Settings URLs")
    func authorizationPanelURLs() {
        #expect(
            KikiAuthorizationPanel.accessibility.settingsURL.absoluteString
                == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        )
        #expect(
            KikiAuthorizationPanel.screenRecording.settingsURL.absoluteString
                == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
        )
    }

    @Test("Authorization panels expose user-facing titles and icons")
    func authorizationPanelLabels() {
        #expect(KikiAuthorizationPanel.accessibility.title == "Accessibility")
        #expect(KikiAuthorizationPanel.accessibility.systemImage == "accessibility")
        #expect(KikiAuthorizationPanel.screenRecording.title == "Screen Recording")
        #expect(KikiAuthorizationPanel.screenRecording.systemImage == "rectangle.on.rectangle")
    }

    @MainActor
    @Test("Authorization host app can be supplied by the caller")
    func hostAppCanBeSuppliedByCaller() {
        let icon = NSImage(size: NSSize(width: 32, height: 32))
        let url = URL(fileURLWithPath: "/Applications/Test.app")
        let hostApp = KikiAuthorizationHostApp(
            displayName: "Test",
            bundleURL: url,
            icon: icon
        )

        #expect(hostApp.displayName == "Test")
        #expect(hostApp.bundleURL == url)
        #expect(hostApp.icon === icon)
    }

    @MainActor
    @Test("Authorization assistant shared instance is available")
    func assistantSharedInstanceIsAvailable() {
        _ = KikiAuthorizationAssistant.shared
    }
}
