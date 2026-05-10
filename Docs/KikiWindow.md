# KikiWindow

`KikiWindow` owns reusable AppKit window presentation for cases where SwiftUI
scene modifiers are not enough.

## Public API

- `KikiWindowConfiguration`: title, size, minimum size, style mask, autosave
  name, titlebar transparency, title visibility, background, movable background,
  hidden traffic-light buttons, and app activation behavior.
- `KikiWindowButtonVisibility`: option set for hiding close, miniaturize, and
  zoom buttons.
- `KikiTransparentWindowBackground`: SwiftUI background bridge that clears the
  hosting `NSWindow` background and optionally makes the titlebar transparent.
- `View.kikiTransparentWindowBackground(...)`: convenience wrapper for the
  bridge.
- `KikiSingleWindowController`: single-instance `NSWindow` presenter that hosts
  SwiftUI content through `NSHostingController`.

## Boundary

Use this target for standalone utility, onboarding, help, and optional paywall
windows. Do not use it for menu bar popovers; those stay in `KikiMenuBar`.
Do not put onboarding state, paywall policy, settings tabs, or product-specific
window flows in this target.
