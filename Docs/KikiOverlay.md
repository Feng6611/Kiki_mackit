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

- `KikiScreenEdgeOverlayController`: long-lived presenter owned by the host
  app.
- `KikiScreenEdgeOverlayPresentation`: display payload and behavior, built
  through the `.lockStarted(...)`, `.lockEnded(...)`, and `.warning(...)`
  factories.
- `KikiOverlayTone`: tone-driven palette (`.alert`, `.success`, `.warning`)
  that maps to the previously hand-tuned color pairs. Hosts that want a
  custom color pass `tint:` and `companionTint:` directly to the factory.
- `KikiScreenEdgeOverlayStyle`: tunable defaults. v1 of this module exposed
  ~25 init parameters; 0.6.0 narrows the public surface to four knobs:
  `glowIntensity`, `toastWidth`, `panelLevel`, and `toastDuration`. The rest
  are no longer publicly mutable so hosts cannot accidentally diverge from
  the Kiki visual rhythm. `KikiScreenEdgeOverlayStyle.screenEdge(glowIntensity:)`
  is the recommended entry point.
- `KikiScreenEdgeOverlayBehavior`: `.persistent` or `.momentary(duration:)`.
- `KikiScreenEdgeOverlayMotion`: `.breathing`, `.breathingWithEntryBurst`,
  `.blink`, or `.steady`.

`KikiScreenEdgeOverlayPalette` remains available as a deprecated compatibility
surface for older hosts. New code should use `KikiOverlayTone` or pass colors
explicitly via the presentation factories.

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
                tone: .alert,
                title: "Keyboard locked",
                subtitle: "Hold Ctrl Option Command L to unlock"
            )
        )
    }

    func showUnlocked() {
        overlay.show(
            .lockEnded(
                tone: .success,
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
