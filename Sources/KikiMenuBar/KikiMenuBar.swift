import AppKit

@MainActor
public enum KikiMenuItem {
    case action(
        title: String,
        keyEquivalent: String = "",
        modifierMask: NSEvent.ModifierFlags = [],
        isEnabled: Bool = true,
        action: @MainActor () -> Void
    )
    case toggle(
        title: String,
        isOn: Bool,
        isEnabled: Bool = true,
        action: @MainActor () -> Void
    )
    case separator

    public var title: String? {
        switch self {
        case .action(let title, _, _, _, _), .toggle(let title, _, _, _):
            return title
        case .separator:
            return nil
        }
    }

    public var isEnabled: Bool {
        switch self {
        case .action(_, _, _, let isEnabled, _), .toggle(_, _, let isEnabled, _):
            return isEnabled
        case .separator:
            return false
        }
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
            case .action(let title, let keyEquivalent, let modifierMask, let isEnabled, let action):
                menu.addItem(makeActionItem(
                    title: title,
                    keyEquivalent: keyEquivalent,
                    modifierMask: modifierMask,
                    isEnabled: isEnabled,
                    action: action
                ))
            case .toggle(let title, let isOn, let isEnabled, let action):
                let menuItem = makeActionItem(
                    title: title,
                    keyEquivalent: "",
                    modifierMask: [],
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
        keyEquivalent: String,
        modifierMask: NSEvent.ModifierFlags,
        isEnabled: Bool,
        action: @escaping @MainActor () -> Void
    ) -> NSMenuItem {
        let target = KikiMenuActionTarget(action: action)

        let item = NSMenuItem(
            title: title,
            action: #selector(KikiMenuActionTarget.performKikiMenuAction),
            keyEquivalent: keyEquivalent
        )
        item.target = target
        item.representedObject = target
        item.keyEquivalentModifierMask = modifierMask
        item.isEnabled = isEnabled
        return item
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
