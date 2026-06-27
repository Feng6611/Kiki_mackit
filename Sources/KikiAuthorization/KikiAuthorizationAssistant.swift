import AppKit
import ApplicationServices
import Foundation

@MainActor
public final class KikiAuthorizationAssistant {
    public static let shared = KikiAuthorizationAssistant()

    private var overlayController: KikiAuthorizationOverlayWindowController?
    private var activationObserver: NSObjectProtocol?
    private var launchObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    private var screenParametersObserver: NSObjectProtocol?
    private var axObserver: AXObserver?
    private var observedSettingsAppElement: AXUIElement?
    private var observedSettingsProcessID: pid_t?
    private var pendingSourceFrameInScreen: CGRect?
    private var didPresentOverlay = false

    private init() {}

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
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }

        if let screenParametersObserver {
            NotificationCenter.default.removeObserver(screenParametersObserver)
            self.screenParametersObserver = nil
        }

        if let launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(launchObserver)
            self.launchObserver = nil
        }

        if let terminateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(terminateObserver)
            self.terminateObserver = nil
        }

        tearDownAXObserver()
        overlayController?.close()
        overlayController = nil
        pendingSourceFrameInScreen = nil
        didPresentOverlay = false
    }

    private func startTrackingSystemSettings() {
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAXObserverRegistrationIfNeeded()
                self?.refreshOverlayPosition()
            }
        }

        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleApplicationLifecycle(notification: notification)
            }
        }

        terminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleApplicationLifecycle(notification: notification)
            }
        }

        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshOverlayPosition()
            }
        }

        installAXObserverIfPossible()
        refreshOverlayPosition()
    }

    private func handleApplicationLifecycle(notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              application.bundleIdentifier == KikiAuthorizationSettingsWindowLocator.bundleIdentifier else {
            return
        }

        if notification.name == NSWorkspace.didTerminateApplicationNotification {
            if observedSettingsProcessID == application.processIdentifier {
                tearDownAXObserver()
            }
            overlayController?.hide()
            return
        }

        refreshAXObserverRegistrationIfNeeded()
        refreshOverlayPosition()
    }

    private func refreshAXObserverRegistrationIfNeeded() {
        guard let settingsApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: KikiAuthorizationSettingsWindowLocator.bundleIdentifier)
            .first else {
            return
        }

        if observedSettingsProcessID == settingsApp.processIdentifier, axObserver != nil {
            return
        }

        tearDownAXObserver()
        installAXObserverIfPossible()
    }

    private func installAXObserverIfPossible() {
        guard let settingsApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: KikiAuthorizationSettingsWindowLocator.bundleIdentifier)
            .first else {
            return
        }

        let appElement = AXUIElementCreateApplication(settingsApp.processIdentifier)
        var observer: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else {
                return
            }

            let assistant = Unmanaged<KikiAuthorizationAssistant>
                .fromOpaque(refcon)
                .takeUnretainedValue()
            Task { @MainActor in
                assistant.refreshOverlayPosition()
            }
        }

        let result = AXObserverCreate(settingsApp.processIdentifier, callback, &observer)
        guard result == .success, let observer else {
            return
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        let notifications: [CFString] = [
            kAXMovedNotification as CFString,
            kAXResizedNotification as CFString,
            kAXWindowMovedNotification as CFString,
            kAXWindowResizedNotification as CFString,
        ]

        var didRegisterNotification = false
        for notification in notifications {
            let registrationResult = AXObserverAddNotification(
                observer,
                appElement,
                notification,
                refcon
            )
            if registrationResult == .success || registrationResult == .notificationAlreadyRegistered {
                didRegisterNotification = true
            }
        }

        guard didRegisterNotification else {
            return
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        axObserver = observer
        observedSettingsAppElement = appElement
        observedSettingsProcessID = settingsApp.processIdentifier
    }

    private func tearDownAXObserver() {
        if let axObserver,
           let observedSettingsAppElement {
            AXObserverRemoveNotification(axObserver, observedSettingsAppElement, kAXMovedNotification as CFString)
            AXObserverRemoveNotification(axObserver, observedSettingsAppElement, kAXResizedNotification as CFString)
            AXObserverRemoveNotification(axObserver, observedSettingsAppElement, kAXWindowMovedNotification as CFString)
            AXObserverRemoveNotification(axObserver, observedSettingsAppElement, kAXWindowResizedNotification as CFString)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver), .commonModes)
        }

        axObserver = nil
        observedSettingsAppElement = nil
        observedSettingsProcessID = nil
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
