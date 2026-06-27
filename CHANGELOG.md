# Changelog

## Unreleased

## 0.6.0 - 2026-06-27

### Added

- tracked `KikiSettingsOpener` fallback logging when the standard
  `Settings...` main-menu item cannot be performed and the package must fall
  back to `showSettingsWindow:`.
- `KikiSettingsMenuPickerRow` for three-or-more-option enumerated settings,
  per macOS HIG.
- `KikiMenuBuilder.menu(from:title:)` pure function so hosts that own their
  own `NSStatusItem` can reuse `KikiMenuItem` semantics without
  `KikiMenuBarController`.
- `KikiOnboarding` module: `KikiOnboardingScaffold`, `KikiOnboardingRow`,
  `KikiOnboardingPermissionRow`, `KikiOnboardingAction`, and
  `KikiOnboardingWindowController`.
- `KikiActivation` module: `KikiActivationPolicyCoordinator` for menu bar
  apps that temporarily promote to `.regular` and restore the previous
  frontmost app.
- `KikiPaywallSheet` preset that arranges header, stats, features, plan
  cards, and primary/secondary actions for the most common paywall shape.
- `KikiOverlayTone` enum (`.alert`, `.success`, `.warning`) so overlay
  presets express intent without hand-tuned color pairs.

### Changed

- `KikiAuthorizationAssistant` follows the System Settings window with
  AX move/resize observers plus the existing workspace activation observer
  instead of a 0.18s `Timer`.
- `KikiSettingsPane` chrome is now just `Form(.grouped)` with top alignment.
  Custom backgrounds, hidden scroll backgrounds, and extra scene padding are
  removed so panes match the system Settings app.
- `KikiScreenEdgeOverlayStyle` public surface narrows to four host-tunable
  values (`glowIntensity`, `toastWidth`, `panelLevel`, `toastDuration`); the
  remaining timing/visual parameters move to internal defaults.
- documented the `KikiPaywallSheet` preset direction for future
  `KikiCommerce.KikiProPaywallSheet` convergence.

### Removed

- `KikiSettingsUI` namespace and its `FormPane`, `LinkButton`, `CopyRow`
  shims and the `AppIdentityView`, `ApplicationRow`, `ApplicationPicker`
  type aliases.
- Deprecated
  `KikiMenuItem.action(title:keyEquivalent:modifierMask:isEnabled:action:)`
  static helper.
- public mutation of `KikiScreenEdgeOverlayStyle` internals; host tuning now
  flows through the narrowed initializer and `screenEdge(glowIntensity:)`.

## 0.5.0 - 2026-06-23

### Added

- Promoted `KikiCommerce` to a first-class documented kit boundary for reusable
  paid-access workflow, not just an implementation detail beside UI modules.
- Added boundary documentation that clarifies the split between
  `RevenueCatCommerceKit` provider transport and `KikiCommerce` app-facing
  reusable monetization workflow.
- Added shared Settings status tones and an authorization status row for
  reusable permission states in menu bar app Settings.
- Added the `KikiTriggerCorner` product for reusable trigger-corner geometry,
  dwell/cooldown state, and AppKit pointer-location monitoring.

### Changed

- Switched `Kiki_mackit` to a remote SwiftPM dependency on
  `RevenueCatCommerceKit` so `KikiCommerce` can ship as a real consumable
  package product instead of a local-only setup.
- Updated README, API conventions, and agent guidance to define Kiki as a
  reusable app kit that may contain reusable UI, platform, authorization, and
  commerce workflow modules.
- `KikiSettingsShell` now keeps tab content alive when switching tabs instead of
  recreating non-selected panes.
- Kept `KikiSettingsOpener.openForMenuBarApp()` in accessory mode when opening
  SwiftUI Settings for menu bar apps, matching Command Reopen's approach and
  avoiding temporary Dock icons.
- Refined `KikiOverlay` toasts into a more compact Raycast-like material
  treatment with smaller accent icons and success palette support.

### Fixed

- `KikiSettingsWindowController` no longer falls back to mutating arbitrary
  visible windows when preparing the Settings scene.
- `KikiSingleWindowController` no longer recenters windows with autosaved
  frames every time they reopen, preserving native macOS window placement
  behavior.

### Tests

- Added focused tests for menu toggle state mapping, Settings opener menu
  traversal, KikiDesign construction, KikiWindow construction, expanded paywall
  display components, and the reusable KikiCommerce workflow.

## 0.4.0 - 2026-05-16

### Added

- Added the `KikiDesign` product for adaptive glass and reusable material surface primitives.
- Added the `KikiWindow` product for SwiftUI-hosted single-window presentation and transparent AppKit window background helpers.
- Expanded `KikiMenuBar` with native menu item declarations, standard shortcuts, status/link/toggle items, settings/about/quit helpers, and SwiftUI popover support.
- Expanded `KikiPaywall` with reusable paywall display models, shell layout, plan cards, feature rows, action labels, and optional standalone window presentation.
- Added an internal `KikiCore` target for package-shared AppKit helpers.

### Changed

- Split `KikiSettings` into focused source files while preserving the public API surface.
- Updated Settings, MenuBar, Paywall, Design, and Window documentation to reflect the current module boundaries.
- Routed repeated URL-opening behavior through shared package-internal helpers.
- Updated app activation helpers to use the macOS 14+ activation API when available.

### Fixed

- Documented the Settings opener fallback selector used after the explicit main-menu Settings item search fails.
- Improved Settings opener behavior coverage for disabled menu items.
