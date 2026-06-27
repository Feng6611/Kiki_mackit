# KikiActivation

`KikiActivation` provides reusable activation-policy coordination for menu
bar apps that temporarily promote themselves to a regular app to install a
menu of their own, then restore the previous frontmost application.

Use it when:

- the app is `LSUIElement` accessory by default;
- a user action needs to show the app's own main menu in the menu bar
  (typical for menu bar apps that want their `Settings...` and `Quit`
  available while a panel is revealed);
- the previous frontmost app must come back when the promoted state ends.

Do not use it for opening the SwiftUI Settings scene. Settings opens through
`KikiSettingsOpener.openForMenuBarApp()` while the app stays in `.accessory`.

## Public API

- `KikiActivationPolicyCoordinator`: long-lived controller owned by the host
  app delegate. Starts in `.accessory`.
  - `start()`: install the initial policy.
  - `begin(reason:)`: capture the current frontmost app (if not us), then
    promote to `.regular` and activate via the macOS 14 `activate(from:)`
    helper. On macOS 13 it uses `activate(ignoringOtherApps:)`.
  - `end()`: restore the previously captured frontmost app via
    `yieldActivation(to:)` then `activate(from:)` on macOS 14+, fall back to
    `activate(options:)` on macOS 13.
  - `reset(toPolicy:reason:)`: re-apply a policy when the app needs to
    cancel a promoted state without restoring a previous app.
- `KikiActivationLogger`: optional sink for activation events. A default
  `OSLog`-backed logger is provided; hosts can pass their own.

## What This Module Does Not Do

- It does not install a main menu. The host decides whether to swap
  `NSApp.mainMenu` during the promoted state and what menu to install.
- It does not decide when to begin or end. The host calls `begin/end` based
  on its product logic (for example: a reveal action).
- It does not maintain a Dock warm-up cache. Hosts that need a Dock
  warm-up for the first activation can opt in via
  `KikiActivationPolicyCoordinator(prewarmsThroughDockOnFirstActivation:)`.

## Example

```swift
import KikiActivation

@MainActor
final class MyAppDelegate: NSObject, NSApplicationDelegate {
    private let activation = KikiActivationPolicyCoordinator(
        prewarmsThroughDockOnFirstActivation: true
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        activation.start()
    }

    func beginReveal() {
        installCompactMainMenu()
        activation.begin(reason: "reveal")
    }

    func endReveal() {
        activation.end()
        restoreStandardMainMenu()
    }
}
```
