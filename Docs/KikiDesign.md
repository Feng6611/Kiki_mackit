# KikiDesign

`KikiDesign` owns cross-surface visual primitives shared by Settings, MenuBar
popovers, Paywall, sheets, and standalone windows.

## Public API

- `KikiDesignColor.proAccent`: Kiki purple for the default
  Pro/access-positive status treatment.
- `KikiDesignColor.systemAccent`: the current macOS system accent color from
  `NSColor.controlAccentColor`.
- `KikiSurfaceDefaults`: stable default corner radius and tint opacity.
- `KikiMaterialSurface`: reusable material plus tint background.
- `View.kikiAdaptiveGlass(in:)`: Liquid Glass on macOS 26+, `.ultraThinMaterial`
  fallback on older systems.
- `View.kikiMaterialSurface(in:material:tint:tintOpacity:)`: shaped material
  surface for cards and panels.
- `View.kikiWindowMaterialBackground(material:tint:tintOpacity:)`: full-window
  or popover background treatment.
- `View.kikiGlassActionForeground()`: foreground treatment for prominent glass
  actions.

## Boundary

This target provides visual treatment only. It does not own app layout, product
copy, state, purchase logic, settings tabs, menu content, or window lifecycle.

Use `proAccent` for Kiki's default positive access treatment. Use
`systemAccent` when the UI should respect the user's macOS accent color.
The Pro token is an opt-in visual default, not access policy: apps still own
what Pro means and may pass an explicit tint. `brandAccent` and the snake-case
aliases are deprecated and scheduled for removal in `0.9.0`.
