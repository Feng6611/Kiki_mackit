import AppKit
import KikiCore
import OSLog

@MainActor
public final class KikiSettingsWindowController {
    private let frameAutosaveName: NSWindow.FrameAutosaveName
    private let minimumContentSize: CGSize

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
        _ = windowTitle
    }

    public var isVisible: Bool {
        visibleSettingsWindows().isEmpty == false
    }

    public func close() {
        for window in visibleSettingsWindows() {
            window.close()
        }
    }

    public func prepareForSettingsScene() {
        activateForSettingsScene()
        DispatchQueue.main.async { [weak self] in
            self?.restoreSettingsWindowFrameIfNeeded()
        }
    }

    fileprivate func activateForSettingsScene() {
        KikiAppActivation.activate()
    }

    fileprivate func visibleSettingsWindows(excluding excludedWindowNumbers: Set<Int> = []) -> [NSWindow] {
        let visibleWindows = NSApp.windows.filter { window in
            window.isVisible
                && window.isMiniaturized == false
                && window.level == .normal
                && excludedWindowNumbers.contains(window.windowNumber) == false
        }

        return visibleWindows.filter { window in
            window.frameAutosaveName == frameAutosaveName
        }
    }

    fileprivate func restoreSettingsWindowFrameIfNeeded() {
        for window in visibleSettingsWindows() {
            window.contentMinSize = minimumContentSize
            window.setFrameUsingName(frameAutosaveName)
            window.setFrameAutosaveName(frameAutosaveName)
            enforceMinimumContentSize(for: window)
        }
    }

    private func enforceMinimumContentSize(for window: NSWindow) {
        let currentContentSize = window.contentLayoutRect.size
        guard currentContentSize.width < minimumContentSize.width
                || currentContentSize.height < minimumContentSize.height else {
            return
        }

        var frame = window.frame
        let targetContentSize = CGSize(
            width: max(currentContentSize.width, minimumContentSize.width),
            height: max(currentContentSize.height, minimumContentSize.height)
        )
        let targetFrame = window.frameRect(forContentRect: CGRect(origin: .zero, size: targetContentSize))
        frame.size.width = targetFrame.size.width
        frame.size.height = targetFrame.size.height
        window.setFrame(frame, display: true)
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

        DispatchQueue.main.async { [weak windowController] in
            windowController?.restoreSettingsWindowFrameIfNeeded()
        }
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
