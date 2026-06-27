# KikiMenuBar

`KikiMenuBar` owns AppKit menu bar plumbing for small macOS apps. It exposes a
menu-item model that hosts declare with closures, two controllers, and a
pure-function builder so non-controller hosts can reuse the same model.

## Public Types

- `KikiMenuItem`: action, toggle, link, status, settings, about, quit,
  separator. Hosts construct an array per refresh; the controller rebuilds the
  `NSMenu` on every show.
- `KikiMenuShortcut`: `KikiMenuShortcut.settings` (command-comma) and
  `KikiMenuShortcut.quit` (command-Q) as the documented defaults; custom keys
  use the explicit init.
- `KikiMenuBuilder.menu(from:title:)`: pure helper that turns
  `[KikiMenuItem]` into an `NSMenu`. Hosts that must own their own
  `NSStatusItem` (for example to control `length` directly) can call this
  without going through `KikiMenuBarController`.
- `KikiMenuBarController`: high-level controller that owns the `NSStatusItem`,
  installs an image/tooltip, and refreshes the menu via the items provider.
- `KikiMenuBarPopoverController`: same `NSStatusItem` lifecycle but uses
  `NSPopover` to host SwiftUI content. Hosts own popover content; Kiki owns
  the AppKit bridge.

## When To Use Each

- Standard menu bar app with a popup menu: `KikiMenuBarController`.
- Menu bar app with a SwiftUI popover: `KikiMenuBarPopoverController`.
- Specialized status item (custom `length`, dual items, hand-rolled click
  routing, accessibility identifier): construct your own `NSStatusItem`, then
  set `statusItem.menu = KikiMenuBuilder.menu(from: items, title: title)`
  inside the click handler. This is the path Hidden Dot uses.

## Style Rules

- Lock/unlock-style modes should prefer one stable symbol and
  `updateButtonState(isActive:)`. Use `updateButtonTint(_:)` only when the
  active state needs more contrast than the system tint provides.
- Menu item actions stay closures, not selectors, so the host does not need
  Objective-C trampolines.
- `Settings...` and `Quit ...` titles come from `KikiMenuItem.settings` and
  `KikiMenuItem.quit(appName:)`; do not hand-author them so the standard
  shortcuts stay attached.

## Removed in 0.6.0

- `KikiMenuItem.action(title:keyEquivalent:modifierMask:isEnabled:action:)`
  static helper. Use
  `.action(title:shortcut:isEnabled:action:)` with `KikiMenuShortcut`.
