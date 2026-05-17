# KikiTriggerCorner

`KikiTriggerCorner` owns reusable macOS trigger-corner detection for apps that
want a pointer dwell in one screen corner to call an app-owned action.

Use it when the host app needs a lightweight alternative to a global hotkey or
menu item. The module polls the current pointer location, checks it against the
selected screen corner, applies dwell/cooldown behavior, and calls the host
callback. It does not install an event tap or suppress input.

## Design Boundary

Kiki owns:

- Corner choices and titles.
- Screen-frame geometry for multi-display layouts.
- Dwell, cooldown, and re-arm behavior.
- `NSEvent.mouseLocation` polling and `NSScreen` frame lookup.
- Test seams for supplying mouse location, screen frames, and time.

Host apps own:

- Settings persistence and UI.
- Access policy, trial/pro gating, analytics, and onboarding decisions.
- The action triggered by the corner, such as lock, unlock, reveal, or focus.
- Any product-specific overlay, toast, or status feedback.

## Primary API

- `KikiTriggerCorner`: persisted/user-facing corner enum.
- `KikiTriggerCornerConfiguration`: enabled state, selected corner, edge size,
  dwell duration, cooldown duration, and polling interval.
- `KikiTriggerCornerMonitor`: long-lived monitor owned by the host app.
- `KikiTriggerCornerGeometry`: pure geometry helper for tests or previews.
- `KikiTriggerCornerActivationState`: pure dwell/re-arm state machine.

## Example

```swift
import KikiTriggerCorner

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()

    private lazy var triggerCornerMonitor = KikiTriggerCornerMonitor(
        configurationProvider: { [weak self] in
            guard let self else {
                return .disabled
            }

            return KikiTriggerCornerConfiguration(
                isEnabled: self.settings.triggerCornerEnabled,
                corner: self.settings.triggerCorner
            )
        },
        onTrigger: { [weak self] in
            self?.toggleAppMode()
        }
    )

    func updateTriggerCornerMonitor(accessIsActive: Bool, appModeIsActive: Bool) {
        if settings.triggerCornerEnabled && (accessIsActive || appModeIsActive) {
            triggerCornerMonitor.start()
        } else {
            triggerCornerMonitor.stop()
        }
    }

    func appModeDidChange() {
        triggerCornerMonitor.disarmUntilExit()
    }
}
```
