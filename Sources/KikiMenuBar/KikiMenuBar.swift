import AppKit
import KikiCore
import SwiftUI

public struct KikiMenuShortcut: Equatable {
    public let key: String
    public let modifiers: NSEvent.ModifierFlags

    public static let settings = KikiMenuShortcut(key: ",", modifiers: .command)
    public static let quit = KikiMenuShortcut(key: "q", modifiers: .command)

    public init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers
    }
}

@MainActor
public enum KikiMenuItem {
    case action(
        title: String,
        shortcut: KikiMenuShortcut? = nil,
        isEnabled: Bool = true,
        action: @MainActor () -> Void
    )
    case toggle(
        title: String,
        isOn: Bool,
        isEnabled: Bool = true,
        action: @MainActor () -> Void
    )
    case link(
        title: String,
        urlString: String,
        isEnabled: Bool = true
    )
    case status(title: String)
    case settings(
        title: String = "Settings...",
        action: @MainActor () -> Void
    )
    case about(
        title: String = "About",
        action: @MainActor () -> Void
    )
    case quit(
        appName: String,
        action: @MainActor () -> Void
    )
    case separator

    public var title: String? {
        switch self {
        case .action(let title, _, _, _),
             .toggle(let title, _, _, _),
             .link(let title, _, _),
             .status(let title),
             .settings(let title, _),
             .about(let title, _):
            return title
        case .quit(let appName, _):
            return "Quit \(appName)"
        case .separator:
            return nil
        }
    }

    public var isEnabled: Bool {
        switch self {
        case .action(_, _, let isEnabled, _),
             .toggle(_, _, let isEnabled, _),
             .link(_, _, let isEnabled):
            return isEnabled
        case .settings, .about, .quit:
            return true
        case .status, .separator:
            return false
        }
    }
}

public extension KikiMenuItem {
    @available(*, deprecated, message: "Use action(title:shortcut:isEnabled:action:) instead.")
    static func action(
        title: String,
        keyEquivalent: String,
        modifierMask: NSEvent.ModifierFlags,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) -> KikiMenuItem {
        let shortcut = keyEquivalent.isEmpty ? nil : KikiMenuShortcut(key: keyEquivalent, modifiers: modifierMask)
        return .action(title: title, shortcut: shortcut, isEnabled: isEnabled, action: action)
    }
}

@MainActor
public final class KikiMenuBarController: NSObject {
    private let title: String
    private let statusItem: NSStatusItem
    private let itemsProvider: () -> [KikiMenuItem]

    public init(
        title: String,
        autosaveName: String? = nil,
        systemImageName: String? = nil,
        accessibilityDescription: String? = nil,
        tooltip: String? = nil,
        itemsProvider: @escaping () -> [KikiMenuItem]
    ) {
        self.title = title
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.itemsProvider = itemsProvider
        super.init()
        configureStatusItem(
            autosaveName: autosaveName,
            systemImageName: systemImageName,
            accessibilityDescription: accessibilityDescription ?? title,
            tooltip: tooltip ?? title
        )
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    public func updateButtonImage(
        systemImageName: String,
        accessibilityDescription: String? = nil
    ) {
        guard let button = statusItem.button else {
            return
        }
        let image = NSImage(systemSymbolName: systemImageName, accessibilityDescription: accessibilityDescription ?? title)
        image?.isTemplate = true
        button.image = image
    }

    public func updateButtonState(isActive: Bool) {
        guard let button = statusItem.button else {
            return
        }
        button.state = isActive ? .on : .off
    }

    public func updateButtonTint(_ tintColor: NSColor?) {
        statusItem.button?.contentTintColor = tintColor
    }

    public func updateButtonTooltip(_ tooltip: String) {
        statusItem.button?.toolTip = tooltip
    }

    private func configureStatusItem(
        autosaveName: String?,
        systemImageName: String?,
        accessibilityDescription: String,
        tooltip: String
    ) {
        statusItem.autosaveName = autosaveName
        guard let button = statusItem.button else {
            return
        }
        button.target = self
        button.action = #selector(showMenu)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = tooltip
        if let systemImageName {
            updateButtonImage(systemImageName: systemImageName, accessibilityDescription: accessibilityDescription)
        }
    }

    @objc private func showMenu() {
        statusItem.kikiShowMenu(makeMenu())
    }

    public func makeMenu() -> NSMenu {
        let menu = NSMenu(title: title)
        menu.autoenablesItems = false

        for item in itemsProvider() {
            switch item {
            case .separator:
                menu.addItem(.separator())
            case .status(let title):
                menu.addItem(makeStatusItem(title: title))
            case .link(let title, let urlString, let isEnabled):
                menu.addItem(makeActionItem(
                    title: title,
                    shortcut: nil,
                    isEnabled: isEnabled,
                    action: {
                        KikiMenuActions.openURL(urlString)
                    }
                ))
            case .settings(let title, let action):
                menu.addItem(makeActionItem(
                    title: title,
                    shortcut: .settings,
                    isEnabled: true,
                    action: action
                ))
            case .about(let title, let action):
                menu.addItem(makeActionItem(
                    title: title,
                    shortcut: nil,
                    isEnabled: true,
                    action: action
                ))
            case .quit(let appName, let action):
                menu.addItem(makeActionItem(
                    title: "Quit \(appName)",
                    shortcut: .quit,
                    isEnabled: true,
                    action: action
                ))
            case .action(let title, let shortcut, let isEnabled, let action):
                menu.addItem(makeActionItem(
                    title: title,
                    shortcut: shortcut,
                    isEnabled: isEnabled,
                    action: action
                ))
            case .toggle(let title, let isOn, let isEnabled, let action):
                let menuItem = makeActionItem(
                    title: title,
                    shortcut: nil,
                    isEnabled: isEnabled,
                    action: action
                )
                menuItem.state = isOn ? .on : .off
                menu.addItem(menuItem)
            }
        }

        return menu
    }

    private func makeActionItem(
        title: String,
        shortcut: KikiMenuShortcut?,
        isEnabled: Bool,
        action: @escaping @MainActor () -> Void
    ) -> NSMenuItem {
        let target = KikiMenuActionTarget(action: action)

        let item = NSMenuItem(
            title: title,
            action: #selector(KikiMenuActionTarget.performKikiMenuAction),
            keyEquivalent: shortcut?.key ?? ""
        )
        item.target = target
        item.representedObject = target
        item.keyEquivalentModifierMask = shortcut?.modifiers ?? []
        item.isEnabled = isEnabled
        return item
    }

    private func makeStatusItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}

@MainActor
public final class KikiMenuBarPopoverController<Content: View>: NSObject {
    private let title: String
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let onWillShow: (@MainActor () -> Void)?

    public init(
        title: String,
        autosaveName: String? = nil,
        systemImageName: String,
        accessibilityDescription: String? = nil,
        tooltip: String? = nil,
        popoverSize: CGSize,
        behavior: NSPopover.Behavior = .transient,
        onWillShow: (@MainActor () -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.onWillShow = onWillShow
        super.init()

        configureStatusItem(
            autosaveName: autosaveName,
            systemImageName: systemImageName,
            accessibilityDescription: accessibilityDescription ?? title,
            tooltip: tooltip ?? title
        )
        configurePopover(
            popoverSize: popoverSize,
            behavior: behavior,
            content: content()
        )
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    public var isShown: Bool {
        popover.isShown
    }

    public func updateButtonImage(
        systemImageName: String,
        accessibilityDescription: String? = nil
    ) {
        guard let button = statusItem.button else {
            return
        }

        let image = NSImage(systemSymbolName: systemImageName, accessibilityDescription: accessibilityDescription ?? title)
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageOnly
    }

    public func close(_ sender: Any? = nil) {
        popover.performClose(sender)
    }

    public func toggle(_ sender: Any? = nil) {
        if popover.isShown {
            close(sender)
            return
        }

        show()
    }

    public func show() {
        onWillShow?()

        guard let button = statusItem.button else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func configureStatusItem(
        autosaveName: String?,
        systemImageName: String,
        accessibilityDescription: String,
        tooltip: String
    ) {
        statusItem.autosaveName = autosaveName
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.toolTip = tooltip
        updateButtonImage(systemImageName: systemImageName, accessibilityDescription: accessibilityDescription)
    }

    private func configurePopover(
        popoverSize: CGSize,
        behavior: NSPopover.Behavior,
        content: Content
    ) {
        popover.behavior = behavior
        popover.animates = true
        popover.contentSize = popoverSize
        popover.contentViewController = NSHostingController(rootView: content)
    }

    @objc private func togglePopover(_ sender: Any?) {
        toggle(sender)
    }
}

public enum KikiMenuActions {
    public static func openURL(_ urlString: String) {
        KikiURLActions.open(urlString)
    }
}

@MainActor
private final class KikiMenuActionTarget: NSObject {
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @objc func performKikiMenuAction() {
        action()
    }
}

private extension NSStatusItem {
    func kikiShowMenu(_ menu: NSMenu) {
        let originalMenu = self.menu
        defer {
            self.menu = originalMenu
        }
        self.menu = menu
        button?.performClick(nil)
    }
}
