import AppKit
import KikiCore
import QuartzCore
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
    /// - Parameters:
    ///   - badgeText: trailing supplementary text — "2 days left", "20% off".
    ///     Use it to make one item carry news the others do not; the system
    ///     draws it the way it draws its own menu badges, which is what makes
    ///     it read as emphasis rather than decoration.
    ///   - systemImage: leading SF Symbol, tinted with `imageTint` when given.
    ///     A menu is a list of equals, so an icon on exactly one item is what
    ///     singles it out; icons on several cancel each other out.
    case action(
        title: String,
        badgeCount: Int? = nil,
        badgeText: String? = nil,
        systemImage: String? = nil,
        imageTint: NSColor? = nil,
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
        title: String = "Settings…",
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
        case .action(let title, _, _, _, _, _, _, _):
            return title
        case .toggle(let title, _, _, _),
             .link(let title, _, _),
             .status(let title),
             .settings(let title, _),
             .about(let title, _):
            return title
        case .quit(let appName, _):
            return String(localized: "Quit \(appName)", bundle: .main, comment: "Menu item. Callers must provide 'Quit %@' in their app's Localizable.xcstrings.")
        case .separator:
            return nil
        }
    }

    public var isEnabled: Bool {
        switch self {
        case .action(_, _, _, _, _, _, let isEnabled, _):
            return isEnabled
        case .toggle(_, _, let isEnabled, _),
             .link(_, _, let isEnabled):
            return isEnabled
        case .settings, .about, .quit:
            return true
        case .status, .separator:
            return false
        }
    }
}

@MainActor
public enum KikiMenuBuilder {
    public static func menu(from items: [KikiMenuItem], title: String) -> NSMenu {
        let menu = NSMenu(title: title)
        menu.autoenablesItems = false

        for item in items {
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
                    title: String(localized: "Quit \(appName)", bundle: .main, comment: "Menu item. Callers must provide 'Quit %@' in their app's Localizable.xcstrings."),
                    shortcut: .quit,
                    isEnabled: true,
                    action: action
                ))
            case .action(
                let title,
                let badgeCount,
                let badgeText,
                let systemImage,
                let imageTint,
                let shortcut,
                let isEnabled,
                let action
            ):
                menu.addItem(makeActionItem(
                    title: title,
                    badgeCount: badgeCount,
                    badgeText: badgeText,
                    systemImage: systemImage,
                    imageTint: imageTint,
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

        alignTitles(in: menu)
        return menu
    }

    /// Keeps every title on one vertical line once any item carries an icon.
    ///
    /// AppKit reserves the image column per item rather than per menu, so a
    /// single icon pushes that one title right and leaves the others where
    /// they were — a menu that reads as accidentally indented. Handing the
    /// remaining items a transparent image of the same size restores the
    /// column while leaving exactly one glyph visible, which is the whole
    /// point of putting an icon on one item.
    private static func alignTitles(in menu: NSMenu) {
        let iconSize = menu.items.compactMap(\.image?.size).max { $0.width < $1.width }
        guard let iconSize else { return }

        let spacer = NSImage(size: iconSize)
        spacer.isTemplate = true

        for item in menu.items where item.image == nil && !item.isSeparatorItem {
            item.image = spacer
        }
    }

    private static func makeActionItem(
        title: String,
        badgeCount: Int? = nil,
        badgeText: String? = nil,
        systemImage: String? = nil,
        imageTint: NSColor? = nil,
        shortcut: KikiMenuShortcut?,
        isEnabled: Bool,
        action: @escaping @MainActor () -> Void
    ) -> NSMenuItem {
        let target = KikiMenuActionTarget(action: action)

        // Badges arrived in macOS 14. Below it the text still has to reach the
        // user, so it joins the title — losing the trailing alignment is a far
        // smaller loss than losing "2 days left" altogether.
        let resolvedTitle: String
        if let badgeText, !isBadgeTextSupported {
            resolvedTitle = "\(title) — \(badgeText)"
        } else {
            resolvedTitle = title
        }

        let item = NSMenuItem(
            title: resolvedTitle,
            action: #selector(KikiMenuActionTarget.performKikiMenuAction),
            keyEquivalent: shortcut?.key ?? ""
        )
        item.target = target
        // NSMenuItem only weakly references its target; representedObject
        // keeps the KikiMenuActionTarget alive for the menu's lifetime.
        item.representedObject = target
        item.keyEquivalentModifierMask = shortcut?.modifiers ?? []
        item.isEnabled = isEnabled
        // Trailing-aligned and secondary — the system treatment for a count in
        // a menu. Callers targeting macOS 13 should fold it into `title`.
        if let badgeCount, #available(macOS 14.0, *) {
            item.badge = NSMenuItemBadge(count: badgeCount)
        }
        if let badgeText, #available(macOS 14.0, *) {
            item.badge = NSMenuItemBadge(string: badgeText)
        }
        if let systemImage {
            let image = NSImage(
                systemSymbolName: systemImage,
                accessibilityDescription: nil
            )
            if let imageTint {
                item.image = image?.withSymbolConfiguration(
                    NSImage.SymbolConfiguration(paletteColors: [imageTint])
                )
            } else {
                item.image = image
            }
        }
        return item
    }

    /// Whether `NSMenuItemBadge` will actually render this run.
    private static var isBadgeTextSupported: Bool {
        if #available(macOS 14.0, *) { true } else { false }
    }

    private static func makeStatusItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
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

    /// Acknowledges an event with a single gentle "breath" of the status
    /// button: scale 1.0 → 1.22 → 1.0 paired with opacity 1.0 → 0.45 → 1.0
    /// over 0.8 s (ease-out inhale, ease-in-out exhale). One-shot, never
    /// stacked, no rotation or overshoot. Honors Reduce Motion by skipping
    /// the scale component.
    public func pulseButton() {
        guard let button = statusItem.button else {
            return
        }
        button.wantsLayer = true
        guard let layer = button.layer,
              layer.animation(forKey: Self.pulseAnimationKey) == nil else {
            return
        }

        let centeredAnchor = CGPoint(x: 0.5, y: 0.5)
        if layer.anchorPoint != centeredAnchor {
            var position = layer.position
            position.x += (centeredAnchor.x - layer.anchorPoint.x) * layer.bounds.width
            position.y += (centeredAnchor.y - layer.anchorPoint.y) * layer.bounds.height
            layer.anchorPoint = centeredAnchor
            layer.position = position
        }

        let animation = Self.makePulseAnimation(
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
        layer.add(animation, forKey: Self.pulseAnimationKey)
    }

    static let pulseAnimationKey = "kikiButtonPulse"

    nonisolated static func makePulseAnimation(reduceMotion: Bool) -> CAAnimationGroup {
        let inhale = CAMediaTimingFunction(name: .easeOut)
        let exhale = CAMediaTimingFunction(name: .easeInEaseOut)
        let peak: NSNumber = 0.375

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [1.0, 0.45, 1.0]
        opacity.keyTimes = [0, peak, 1]
        opacity.timingFunctions = [inhale, exhale]

        var animations: [CAAnimation] = [opacity]
        if !reduceMotion {
            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [1.0, 1.22, 1.0]
            scale.keyTimes = [0, peak, 1]
            scale.timingFunctions = [inhale, exhale]
            animations.append(scale)
        }

        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = 0.8
        return group
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
        KikiMenuBuilder.menu(from: itemsProvider(), title: title)
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
        // Restoring via defer relies on performClick(nil) presenting the menu
        // synchronously. If this ever moves to an asynchronous presentation
        // (e.g. popUpMenu), restore from menuDidClose instead.
        defer {
            self.menu = originalMenu
        }
        self.menu = menu
        button?.performClick(nil)
    }
}
