import AppKit
import KikiCore
import OSLog

@MainActor
protocol KikiSettingsWindowManaging: AnyObject {
    var isVisible: Bool { get }
    func configure(
        frameAutosaveName: NSWindow.FrameAutosaveName,
        idealContentSize: CGSize,
        minimumContentSize: CGSize,
        maximumContentSize: CGSize
    )
    func close()
}

extension NSWindow: KikiSettingsWindowManaging {
    func configure(
        frameAutosaveName: NSWindow.FrameAutosaveName,
        idealContentSize: CGSize,
        minimumContentSize: CGSize,
        maximumContentSize: CGSize
    ) {
        let savedWindowSize = kikiSavedWindowFrameSize(for: frameAutosaveName)
        let maximumWindowSize = frameRect(
            forContentRect: CGRect(origin: .zero, size: maximumContentSize)
        ).size
        let savedFrameExceedsMaximum = savedWindowSize.map {
            $0.width > maximumWindowSize.width || $0.height > maximumWindowSize.height
        } ?? false

        setFrameUsingName(frameAutosaveName)
        setFrameAutosaveName(frameAutosaveName)

        let restoredContentSize = contentLayoutRect.size
        contentMinSize = minimumContentSize
        contentMaxSize = maximumContentSize

        let currentContentSize = contentLayoutRect.size
        let exceedsMaximum = savedFrameExceedsMaximum
            || restoredContentSize.width > maximumContentSize.width
            || restoredContentSize.height > maximumContentSize.height
        let targetContentSize: CGSize

        if exceedsMaximum {
            // Older Kit versions allowed Settings to expand without a bound.
            // Reset those distorted saved frames as a whole instead of keeping
            // an awkward aspect ratio after clamping just one dimension.
            targetContentSize = idealContentSize
        } else {
            targetContentSize = CGSize(
                width: max(currentContentSize.width, minimumContentSize.width),
                height: max(currentContentSize.height, minimumContentSize.height)
            )
        }

        guard targetContentSize != currentContentSize else {
            return
        }

        var targetWindowFrame = frame
        let targetFrameSize = frameRect(
            forContentRect: CGRect(origin: .zero, size: targetContentSize)
        ).size
        targetWindowFrame.size = targetFrameSize
        setFrame(targetWindowFrame, display: true)
    }
}

// Best-effort parse of AppKit's private "NSWindow Frame <name>" UserDefaults
// format, used only to decide whether the autosaved frame exceeds the maximum
// before setFrameUsingName restores it. Not an authoritative API: parse
// failure degrades to nil, which skips the reset rather than forcing one.
private func kikiSavedWindowFrameSize(
    for autosaveName: NSWindow.FrameAutosaveName,
    defaults: UserDefaults = .standard
) -> CGSize? {
    guard let value = defaults.string(forKey: "NSWindow Frame \(autosaveName)") else {
        return nil
    }

    let components = value
        .split(whereSeparator: { $0.isWhitespace })
        .compactMap { Double($0) }
    guard components.count >= 4 else {
        return nil
    }

    return CGSize(width: components[2], height: components[3])
}

@MainActor
public final class KikiSettingsWindowController {
    private let frameAutosaveName: NSWindow.FrameAutosaveName
    private let idealContentSize: CGSize
    private let minimumContentSize: CGSize
    private let maximumContentSize: CGSize
    private weak var settingsWindow: (any KikiSettingsWindowManaging)?

    public init(
        frameAutosaveName: String,
        idealContentSize: CGSize = CGSize(
            width: KikiSettingsDefaults.windowWidth,
            height: KikiSettingsDefaults.windowHeight
        ),
        minimumContentSize: CGSize = CGSize(
            width: KikiSettingsDefaults.minimumWindowWidth,
            height: KikiSettingsDefaults.minimumWindowHeight
        ),
        maximumContentSize: CGSize = CGSize(
            width: KikiSettingsDefaults.maximumWindowWidth,
            height: KikiSettingsDefaults.maximumWindowHeight
        ),
        windowTitle: String = "Settings"
    ) {
        self.frameAutosaveName = NSWindow.FrameAutosaveName(frameAutosaveName)
        self.idealContentSize = idealContentSize
        self.minimumContentSize = minimumContentSize
        self.maximumContentSize = maximumContentSize
        // Retained for source compatibility. Exact view registration makes
        // title-based window discovery unnecessary.
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
            idealContentSize: idealContentSize,
            minimumContentSize: minimumContentSize,
            maximumContentSize: maximumContentSize
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
        // Selector comparison is locale-independent; the English title match
        // below fails as soon as the app menu is localized.
        if let action = item.action,
           action == Selector(("showSettingsWindow:"))
            || action == Selector(("showPreferencesWindow:")) {
            return true
        }

        if item.keyEquivalent == "," {
            return true
        }

        // Best-effort English fallback for non-SwiftUI menus whose Settings
        // item uses a custom action selector. Localized menus are expected to
        // match via the selector or key equivalent above.
        let normalizedTitle = item.title
            .replacingOccurrences(of: "…", with: "...")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return normalizedTitle == "settings..."
            || normalizedTitle == "preferences..."
    }
}
