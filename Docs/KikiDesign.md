# KikiDesign

`KikiDesign` owns cross-surface visual primitives shared by Settings, MenuBar
popovers, Paywall, sheets, and standalone windows.

## Public API

- `KikiDesignColor.proAccent`: Kiki purple for the default
  Pro/access-positive status treatment.
- `KikiDesignColor.systemAccent`: the current macOS system accent color from
  `NSColor.controlAccentColor`.
- `KikiSurfaceDefaults`: stable default corner radius and tint opacity.
- `KikiDesignTokens`: shared opacity, corner-radius, and separator tokens for
  custom chrome (cards, badges, hero surfaces) that system controls don't
  cover. Features should use these instead of per-component magic numbers.
- `KikiMaterialSurface`: reusable material plus tint background.
- `View.kikiAdaptiveGlass(in:)`: Liquid Glass on macOS 26+, `.ultraThinMaterial`
  fallback on older systems.
- `View.kikiMaterialSurface(in:material:tint:tintOpacity:)`: shaped material
  surface for cards and panels.
- `View.kikiWindowMaterialBackground(material:tint:tintOpacity:)`: full-window
  or popover background treatment.
- `View.kikiGlassActionForeground()`: foreground treatment for prominent glass
  actions.

## Sheet sizing and lifecycle

`KikiSheetShell` supplies fixed-width card chrome for a SwiftUI `.sheet`.
Its existing initializers accept minimum, ideal and maximum heights, optional
close handling, content, and an optional pinned footer. Equal minimum and
maximum heights produce a fixed-height shell. `idealHeight` is only the
initial estimate until measurement arrives.

Content and footer each remain mounted once in their own stable `ScrollView`.
Separate preference keys measure the visible documents at the configured width;
there is no hidden measurement copy and crossing a height threshold does not
restart caller `onAppear` or `.task` work. A parent removing the shell or changing
its identity still starts a new lifecycle normally.

The shell clamps the sum of both natural heights to its bounds. Ordinary footers
retain their natural height beneath the scrolling content. A footer taller than
half the resolved shell height gets a half-height scrolling viewport, leaving
space for content. Callers supply padding for both regions. With no footer,
content receives the full height.

`KikiSheetShellHostingTests` exercises actual `NSHostingView` layout, document
scrolling, host resizing, fixed/max heights, oversized and absent footers, and
single lifecycle/task execution across size changes.

## Boundary

This target provides visual treatment only. It does not own app layout, product
copy, state, purchase logic, settings tabs, menu content, or window lifecycle.

Use `proAccent` for Kiki's default positive access treatment. Use
`systemAccent` when the UI should respect the user's macOS accent color.
The Pro token is an opt-in visual default, not access policy: apps still own
what Pro means and may pass an explicit tint.
