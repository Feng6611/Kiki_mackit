# KikiAuthorization

`KikiAuthorization` provides a reusable macOS privacy-permission helper. It can
open the relevant System Settings privacy pane and show a lightweight overlay
that lets the user drag the current app into the permission list.

The package owns only the platform mechanism. The product app still owns when
to ask, what copy to show around the request, and how missing permission affects
the feature.

## API

```swift
import KikiAuthorization

@MainActor
func showAccessibilityHelp() {
    KikiAuthorizationAssistant.shared.present(panel: .accessibility)
}
```

Supported panels:

- `.accessibility`
- `.screenRecording`

The app can also inspect current state:

```swift
let isAllowed = KikiAuthorizationPanel.accessibility.isAuthorized
```

Use `requestSystemPrompt()` only when the app intentionally wants the native
system prompt. The drag helper remains useful when the user needs to manually
add the app in System Settings.

## Boundaries

KikiAuthorization may:

- open System Settings privacy panes;
- expose current authorization status for supported panels;
- present and dismiss the helper overlay;
- provide a draggable app row for manual authorization.

KikiAuthorization must not:

- decide whether a product feature is blocked;
- own onboarding, paywall, or recovery routing;
- hardcode product-specific copy beyond safe defaults;
- store app permission decisions.

## Assistant Mechanics (0.6.0)

The assistant follows the System Settings window without polling on a timer.
It listens for these signals:

- `NSWorkspace.didActivateApplicationNotification` to detect when System
  Settings becomes frontmost or yields back to the host.
- `kAXMovedNotification` and `kAXResizedNotification` on the System Settings
  application AX element to update the overlay position when the user drags
  or resizes the Settings window.
- `NSApplication.didChangeScreenParametersNotification` to re-anchor the
  overlay after display changes.

If Accessibility is not granted (or AX observer creation fails), the
assistant falls back to a one-shot positioning using the current frontmost
System Settings window snapshot. No `Timer` is installed.

When `KikiAuthorizationAssistant.shared.dismiss()` is called, every observer
and the AX observer are torn down on the main actor.

## Reference

This component is independently implemented for Kiki and inspired by
[zats/permiso](https://github.com/zats/permiso), which demonstrates a draggable
app helper for macOS privacy permissions.
