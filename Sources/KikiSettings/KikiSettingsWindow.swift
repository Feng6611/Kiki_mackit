import AppKit
import KikiCore
import OSLog

@MainActor
protocol KikiSettingsWindowManaging: AnyObject {
    var isVisible: Bool { get }
    func configure(
        frameAutosaveName: NSWindow.FrameAutosaveName,
        minimumContentSize: CGSize
    )
    func close()
}

extension NSWindow: KikiSettingsWindowManaging {
    func configure(
        frameAutosaveName: NSWindow.FrameAutosaveName,
        minimumContentSize: CGSize
    ) {
        contentMinSize = minimumContentSize
        setFrameUsingName(frameAutosaveName)
        setFrameAutosaveName(frameAutosaveName)

        let currentContentSize = contentLayoutRect.size
        guard currentContentSize.width < minimumContentSize.width
                || currentContentSize.height < minimumContentSize.height else {
            return
        }

        var targetWindowFrame = frame
        let targetContentSize = CGSize(
            width: max(currentContentSize.width, minimumContentSize.width),
            height: max(currentContentSize.height, minimumContentSize.height)
        )
        let targetFrameSize = frameRect(
            forContentRect: CGRect(origin: .zero, size: targetContentSize)
        ).size
        targetWindowFrame.size = targetFrameSize
        setFrame(targetWindowFrame, display: true)
    }
}

@MainActor
public final class KikiSettingsWindowController {
    private let frameAutosaveName: NSWindow.FrameAutosaveName
    private let minimumContentSize: CGSize
    private weak var settingsWindow: (any KikiSettingsWindowManaging)?

    public init(
        frameAutosaveName: String,
        minimumContentSize: CGSize = CGSize(
            width: KikiSettingsDefaults.minimumWindowWidth,
            height: KikiSettingsDefaults.minimumWindowHeight
        ),
        windowTitle: String = "Settings"
    ) {
        self.frameAutosaveName = NSWindow.FrameAutosaveName(frameAutosaveName)
        self.minimumContentSize = minimumContentSize
        // Retained for 0.6 source compatibility. Exact view registration
        // makes title-based window discovery unnecessary.
        _ = windowTitle
    }

    public var isVisible: Bool {
        settingsWindow?.isVisible == true
    }

    public func close() {
        settingsWindow?.close()
    }

    public func prepareForSettingsScene() {
        activateForSettingsScene()
    }

    fileprivate func activateForSettingsScene() {
        KikiAppActivation.activate()
    }

    func register(window: NSWindow) {
        register(managedWindow: window)
    }

    func register(managedWindow: any KikiSettingsWindowManaging) {
        guard (settingsWindow as AnyObject?) !== (managedWindow as AnyObject) else {
            return
        }

        settingsWindow = managedWindow
        managedWindow.configure(
            frameAutosaveName: frameAutosaveName,
            minimumContentSize: minimumContentSize
        )
    }
}

@MainActor
public final class KikiSettingsOpener {
    private static let logger = Logger(subsystem: "kiki.mackit", category: "settings")
    private let windowController: KikiSettingsWindowController?

    public init(windowController: KikiSettingsWindowController? = nil) {
        self.windowController = windowController
    }

    public func prepare() {
        windowController?.prepareForSettingsScene()
    }

    public func open(preparesWindow: Bool = true) {
        if preparesWindow {
            prepare()
        }

        if performMainMenuSettingsItem() {
            return
        }

        // SwiftUI's Settings scene does not expose a public imperative opener,
        // so this mirrors the selector AppKit installs for the standard menu
        // item after the explicit menu search above has failed.
        Self.logger.notice("Using private showSettingsWindow: fallback after standard Settings menu lookup failed")
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    public func openForMenuBarApp(preparesWindow: Bool = true) {
        if preparesWindow {
            windowController?.activateForSettingsScene()
        }

        open(preparesWindow: false)
    }

    private func performMainMenuSettingsItem() -> Bool {
        guard let mainMenu = NSApp.mainMenu else {
            return false
        }

        return performSettingsItem(in: mainMenu)
    }

    private func performSettingsItem(in menu: NSMenu) -> Bool {
        for (index, item) in menu.items.enumerated() {
            if isSettingsItem(item), item.isEnabled {
                menu.performActionForItem(at: index)
                return true
            }

            if let submenu = item.submenu,
               performSettingsItem(in: submenu) {
                return true
            }
        }

        return false
    }

    private func isSettingsItem(_ item: NSMenuItem) -> Bool {
        if item.keyEquivalent == "," {
            return true
        }

        let normalizedTitle = item.title
            .replacingOccurrences(of: "…", with: "...")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return normalizedTitle == "settings..."
            || normalizedTitle == "preferences..."
    }
}
