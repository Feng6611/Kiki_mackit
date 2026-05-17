# KikiOverlay

`KikiOverlay` owns reusable non-interactive overlay feedback for macOS apps.

Use it when an app needs a transient or persistent visual layer over the current
screen without taking focus or receiving pointer events. The module currently
provides a screen-edge overlay paired with a Kiki material toast.

## Design Boundary

The module name uses `Overlay` instead of `HUD` because the component is not an
instrument panel or controls surface. It is a non-interactive visual layer that
communicates app mode changes.

Kiki owns:

- Non-activating global `NSPanel` presentation.
- All-Spaces and full-screen-compatible overlay behavior.
- Screen-edge glow, corner accents, trace-in animation, breathing, blink, and
  compact Kiki material toast visuals.
- Reusable motion rhythm, intensity, breathing expansion, and sizing defaults.
- Composite style mapping for a single host-facing maximum intensity control.
- Presets for common mode feedback such as lock started, lock ended, and warning.

Host apps own:

- Product-specific copy and shortcut text.
- Business state and policy.
- Product-specific color meaning beyond reusable defaults.
- Decisions about which app states should show overlays.

## Primary API

- `KikiScreenEdgeOverlayController`: long-lived presenter owned by the host app.
- `KikiScreenEdgeOverlayPresentation`: display payload and behavior.
- `KikiScreenEdgeOverlayStyle`: reusable timing, intensity, sizing, and panel
  defaults. Use `KikiScreenEdgeOverlayStyle.screenEdge(glowIntensity:)` when an
  app wants a simple user-facing maximum intensity control; breathing rhythm is
  a Kiki design default, not a host app setting.
- `KikiScreenEdgeOverlayBehavior`: `.persistent` or `.momentary(duration:)`.
- `KikiScreenEdgeOverlayMotion`: `.breathing`, `.breathingWithEntryBurst`,
  `.blink`, or `.steady`.
- `KikiScreenEdgeOverlayPalette`: shared orange, success, and warning defaults.

## Example

```swift
import KikiOverlay

@MainActor
final class AppFeedback {
    private let overlay = KikiScreenEdgeOverlayController(
        style: .screenEdge(glowIntensity: 0.85)
    )

    func updateStyle(maximumIntensity: Double) {
        overlay.updateStyle(.screenEdge(glowIntensity: maximumIntensity))
    }

    func showLocked() {
        overlay.show(
            .lockStarted(
                title: "Keyboard locked",
                subtitle: "Hold Ctrl Option Command L to unlock"
            )
        )
    }

    func showUnlocked() {
        overlay.show(
            .lockEnded(
                title: "Keyboard unlocked",
                subtitle: "Keyboard input is flowing normally."
            )
        )
    }

    func hide() {
        overlay.hideImmediately()
    }
}
```
