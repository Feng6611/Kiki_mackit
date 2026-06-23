# KikiDesign

`KikiDesign` owns cross-surface visual primitives shared by Settings, MenuBar
popovers, Paywall, sheets, and standalone windows.

## Public API

- `KikiDesignColor.brandAccent`: Kiki brand purple for product-owned brand
  highlights with a modern native macOS accent direction.
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

Use `brandAccent` when the UI needs the Kiki product family color. Use
`systemAccent` when the UI should respect the user's macOS accent color.
