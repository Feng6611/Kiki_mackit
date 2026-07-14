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
  SwiftUI content through `NSHostingView`.

Transparent utility windows use a dedicated rounded content container and
reapply their non-opaque surface after sheet, focus, and resize transitions.
This keeps the parent window's corners clipped while a SwiftUI sheet is
presented above it.

## Boundary

Use this target for standalone utility, onboarding, help, and optional paywall
windows. Do not use it for menu bar popovers; those stay in `KikiMenuBar`.
Do not put onboarding state, paywall policy, settings tabs, or product-specific
window flows in this target.

## SwiftUI Window vs KikiSingleWindowController

Use SwiftUI `Window`/`WindowGroup` when the window is a normal app window
with standard chrome, default frame, and no transparency. SwiftUI scenes
handle activation, frame autosave, and `commands` for free.

Use `KikiSingleWindowController` when the host needs any of the following:

- transparent window background (via `KikiTransparentWindowBackground`);
- non-standard `styleMask` (hidden traffic-light buttons, transparent
  titlebar, movable by background);
- single-instance window controlled from AppKit code that lives outside a
  SwiftUI scene tree (for example a menu bar app that does not declare an
  extra `WindowGroup`);
- short-lived utility windows that need an explicit lifecycle and a
  programmatic close.
