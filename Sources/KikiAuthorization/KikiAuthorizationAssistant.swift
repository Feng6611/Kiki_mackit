import AppKit
import Foundation

@MainActor
public final class KikiAuthorizationAssistant {
    public static let shared = KikiAuthorizationAssistant()

    private var overlayController: KikiAuthorizationOverlayWindowController?
    private var trackingTimer: Timer?
    private var activationObserver: NSObjectProtocol?
    private var pendingSourceFrameInScreen: CGRect?
    private var didPresentOverlay = false

    public init() {}

    public func present(
        panel: KikiAuthorizationPanel,
        sourceFrameInScreen: CGRect? = nil,
        instruction: String? = nil
    ) {
        present(
            panel: panel,
            hostApp: .current(),
            sourceFrameInScreen: sourceFrameInScreen,
            instruction: instruction
        )
    }

    public func present(
        panel: KikiAuthorizationPanel,
        hostApp: KikiAuthorizationHostApp,
        sourceFrameInScreen: CGRect? = nil,
        instruction: String? = nil
    ) {
        dismiss()

        pendingSourceFrameInScreen = sourceFrameInScreen
        overlayController = KikiAuthorizationOverlayWindowController(
            hostApp: hostApp,
            panel: panel,
            instruction: instruction,
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        openSettings(for: panel)
        startTrackingSystemSettings()
    }

    public func openSettings(for panel: KikiAuthorizationPanel) {
        NSWorkspace.shared.open(panel.settingsURL)
    }

    public func dismiss() {
        trackingTimer?.invalidate()
        trackingTimer = nil

        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }

        overlayController?.close()
        overlayController = nil
        pendingSourceFrameInScreen = nil
        didPresentOverlay = false
    }

    private func startTrackingSystemSettings() {
        let timer = Timer(timeInterval: 0.18, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshOverlayPosition()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshOverlayPosition()
            }
        }

        refreshOverlayPosition()
    }

    private func refreshOverlayPosition() {
        guard let snapshot = KikiAuthorizationSettingsWindowLocator.frontmostWindow() else {
            overlayController?.hide()
            return
        }

        if didPresentOverlay {
            overlayController?.updatePosition(
                settingsFrame: snapshot.frame,
                visibleFrame: snapshot.visibleFrame
            )
            return
        }

        overlayController?.present(
            from: pendingSourceFrameInScreen,
            settingsFrame: snapshot.frame,
            visibleFrame: snapshot.visibleFrame
        )
        didPresentOverlay = true
    }
}
