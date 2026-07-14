# Changelog

## Unreleased

## 0.8.1 - 2026-07-14

### Fixed

- Transparent utility windows now keep their non-opaque rounded content clip
  through sheet presentation and focus/resize transitions, so an onboarding
  window stays rounded behind an attached paywall sheet.

## 0.8.0 - 2026-07-14

### Fixed

- Onboarding custom steps now receive distinct page identities and direction-aware slide transitions, preventing stale text/image remnants during navigation.
- A lone onboarding action now stays centered at the Command Reopen `200pt` width instead of expanding across the window when Skip is disabled.
- Transparent onboarding utilities now use a borderless, non-opaque window with a draggable background, preserving material transparency without the detached title-bar shadow line.
- Transparent utilities now clip their hosted content to a continuous 20pt corner radius while retaining the native window shadow.
- Onboarding actions can be disabled for event-driven steps such as waiting for a trigger-corner gesture.
- Onboarding paywall sheets now fit inside the welcome-window envelope at `520×520` instead of expanding to `560×620`.

- Resolve the host app icon from `CFBundleIconFile` / `CFBundleIconName` in the
  main bundle before falling back to `NSApp.applicationIconImage`, so standard
  About panes do not display AppKit's generic placeholder.
- Restore the onboarding welcome-window default to `560×520`; taller paywall
  sheets remain a separate presentation instead of defining welcome geometry.
- Restored the source-compatible `windowTitle` parameter on
  `KikiSettingsWindowController.init`. The parameter remains a no-op, but Starter was a real 0.7 caller and
  proved that repository-local usage search was not a safe compatibility gate.

### Documentation

- Defined Feature presets as the default App integration layer and Atoms as the
  advanced escape layer for Settings, Onboarding, and Paywall.
- Added a cross-repository public API compatibility rule.

## 0.7.3 - 2026-07-05

### Changed

- `KikiAccessStatusTone` now carries the canonical tone→SF Symbol→color
  mapping (`systemImage`, `settingsTone`, `foregroundColor(tint:)`). Hosts
  no longer reimplement the per-tone icon/color switch. `trial` uses
  `clock.badge.checkmark` + `.secondary`; `active` uses `checkmark.seal` +
  host tint (no longer `.green`); `expired` uses `exclamationmark.triangle`
  + `.orange`; `neutral` uses `info.circle` + `.secondary`.
- `KikiSettingsStatusRow` accepts a `tint: Color` parameter. When the tone
  is `.accent`, the row renders with the host-supplied tint instead of a
  hardcoded purple. `KikiStandardAboutPane` threads the tint through so
  the access-status row matches the app's brand color.
- `KikiStandardAboutLinks` defaults to three links: `website`, `feedback`,
  `github`. `terms` and `privacy` moved out — they belong in the paywall
  footer now. `support` renamed to `github` with a code-bracket SF Symbol.
  `KikiStandardAboutLink` derives `envelope` for `mailto:` URLs (was
  `doc`).
- `KikiPaywallSheet` renders plans as vertical `KikiPaywallPlanCard`s in
  an `HStack` instead of horizontal `KikiPaywallPlanRow`s in a `VStack`.
  Stats wrap in a new `KikiPaywallStatsCard` tinted card. The header title
  is 24pt bold (was 28pt rounded). `KikiPaywallMessage` is plain text
  (no pill background). Footer links use `Button` with `.link` style
  instead of `Link` styled `.secondary`.
- `KikiOnboardingScaffold` accepts an optional `appIcon: NSImage?`. When
  provided, renders an 88×88 app-icon hero (cornerRadius 20, shadow)
  instead of the SF Symbol. Title is 24pt bold (was 30pt rounded). Primary
  button uses `.tint(tint)`. Optional `stepIndex`/`stepCount` show
  `KikiOnboardingProgressDots` above the action area.
- `KikiOnboardingWindowController` uses `KikiWindow.transparentUtility`
  with `hiddenButtons: .all` — transparent titlebar, no traffic lights.
  Default size is 680×680 (was 560×520).

### Added

- `KikiOnboardingProgressDots` atom: `count` + `currentIndex` + `tint`,
  renders a row of capsules (active = tint, inactive = secondary 0.25).
- `KikiPaywallStatsCard` atom: wraps `KikiPaywallStatItem`s in a tinted
  rounded card.
- `KikiSettingsDebugPreviewRow<Item>` atom: segmented picker with debug
  defaults ("Test override" title, `hammer` icon, orange tint when
  override active). Generic over `Hashable` `Item` so hosts wire it to
  their own preview-mode enum.

## 0.7.2 - 2026-07-05

### Changed

- `KikiStandardAboutPane` now composes the existing row atoms
  (`KikiAppIdentityView` + `KikiSettingsStatusRow` +
  `KikiSettingsLinkRow` + `KikiSettingsCopyRow`) instead of rendering a
  custom `KikiAccessStatusCard` and minimal link buttons. Status appears
  as a tappable row with value + chevron; links show title + derived
  host/email value + trailing icon. `KikiAccessStatusCard` remains as an
  atom for other contexts.
- `KikiStandardAboutLink` now carries non-optional `value`, `systemImage`,
  and `kind` fields, derived in the init. `mailto:` URLs auto-resolve to
  `.copy` kind with the email as value; `https` URLs derive the host as
  value. Hosts can override any field by constructing the link directly.
- `KikiOnboardingPaywall` now delegates to `KikiPaywallSheet` with
  `size: .onboarding` instead of duplicating the sheet's stats/features/
  plans/actions layout (~70 lines removed). Added `KikiPaywallSheetSize`
  enum (`.compact` / `.onboarding`) and a `size` parameter on every
  `KikiPaywallSheet` initializer.
- `KikiOnboardingCoordinator`'s paywall-handoff placeholder now uses a
  new `KikiOnboardingLoadingScaffold` atom that shares the scaffold's
  background, frame, and accessibility label, instead of a hand-rolled
  `VStack { ProgressView(); Text("Loading…") }`.
- Onboarding step transitions use `.transition(.opacity.combined(with:
  .move(edge: .trailing)))` + `.animation(.easeInOut(duration: 0.22))`
  instead of `.id(currentStepIndex)` rebuilds, so advancing/backing
  animates instead of jumping.

### Removed

- `KikiStandardAboutPane.onOpenLink` parameter. No consumer used it, and
  `KikiSettingsLinkRow` already opens URLs via `NSWorkspace`. Hosts
  needing custom routing build their own about from the same atoms.

## 0.7.1 - 2026-07-05

### Fixed

- Onboarding welcome step's optional skip button now routes through
  `coordinator.skip()` instead of calling `coordinator.finish()` directly.
  When `configuration.canSkip == false`, the skip button is hidden rather
  than presenting a working skip affordance that bypasses the documented
  guard.
- `KikiOnboardingCoordinator.back()` now re-runs non-interactive step
  handling. Stepping back into a `.paywallHandoff` step re-fires
  `onPaywallHandoff` (or auto-advances when no callback is set) instead of
  leaving the placeholder visible.
- `KikiSettingsCoordinator<Tab>` no longer exposes `navigation`,
  `opener`, `windowController`, and `tabs` as public properties. Hosts
  route through `select(_:)`, `open(tab:)`, `close()`, and `prepare()`;
  `KikiSettingsCoordinatorView` still composes them internally.
- `KikiStandardAboutPane` is `@MainActor`-isolated so the
  `NSApp.applicationIconImage` default argument evaluates on the main
  actor under Swift 6 strict concurrency.
- `KikiAccessStatusCard` renders a disabled button when
  `presentation.actionTitle` is set but no `action` is supplied, instead
  of silently dropping the affordance.
- `KikiPaywallActionPresentation` and `KikiPaywallActionConfig` now
  conform to `Identifiable` with a stable `UUID` id. Paywall presets
  use `ForEach(…, id: \.id)` instead of `id: \.offset`, so reordering
  or inserting secondary actions no longer glitches SwiftUI animations.
- `KikiAuthorizationAssistant.init()` is `public` again. The 0.6.0
  regression that made it `private` broke callers that constructed their
  own assistant and blocked testability of the new AX-observer logic.
- Removed the no-op `windowTitle` parameter from
  `KikiSettingsWindowController.init`. This was later restored as a deprecated
  overload after the workspace Starter proved it was still a source caller.

### Documentation

- `Docs/KikiCommerce.md` clarifies that `KikiCommerce` was removed *in*
  0.7.0, not before.
- `CHANGELOG.md` 0.7.0 entry now lists all three `KikiCommerceKit`
  targets (`KikiCommerceCore` + `KikiRevenueCat` + `KikiCommercePresentation`)
  and names `CommerceClient` migration consistently with the new package.

## 0.7.0 - 2026-07-05

### Added

- `KikiPaywallPresentation`, `KikiPaywallAccessState`,
  `KikiPaywallPlanPresentation`, `KikiPaywallActionPresentation`, and
  `KikiPaywallLinkPresentation`: Commerce-agnostic view models for paywall
  surfaces. The host supplies the primary and ordered secondary actions, so
  Kit does not infer purchase, restore, trial, or dismiss policy.
- `KikiCompactPaywall` and `KikiOnboardingPaywall` preset views that
  consume a `KikiPaywallPresentation` plus a selected-plan binding.
- `KikiAppMetadata`, `KikiAppMetadata.bundle(_:)`, `KikiStandardAboutLink`,
  and `KikiStandardAboutLinks` in `KikiSettings`.
- `KikiAccessStatusTone`, `KikiAccessStatusPresentation`, and
  `KikiAccessStatusCard` for a Commerce-agnostic access status card.
- `KikiStandardAboutPane` composing `KikiAboutPane` with an optional
  status card and the ordered `KikiStandardAboutLinks` rows.
- `KikiSettingsCoordinator<Tab>` and `KikiSettingsCoordinatorView` for a
  preset Settings flow that owns navigation, opener, and window
  controller.
- `KikiOnboardingStep` (welcome / features / permission / success /
  paywallHandoff / custom) with typed content structs. The `custom` view
  builder receives a `KikiOnboardingNavigation` so it can drive
  `advance` / `back` / `skip` / `finish` without capturing the
  coordinator.
- `KikiOnboardingNavigation`: small struct of `@MainActor` closures
  built by `KikiOnboardingCoordinator` and handed to custom step views.
- `KikiOnboardingConfiguration.canSkip` (default `false`) plus
  `KikiOnboardingCoordinator.canSkip` and `skip()`. `skip()` is a guarded
  no-op when `canSkip` is false; otherwise it commits completion through
  `finish()`.
- `KikiSettingsCoordinator.close()` and
  `KikiSettingsWindowController.close()` for dismissing the Settings
  window imperatively from any trigger.
- `KikiOnboardingConfiguration`, `KikiOnboardingCompletionStore`
  protocol, `KikiOnboardingUserDefaultsCompletionStore`,
  `KikiOnboardingInMemoryCompletionStore`, and
  `KikiOnboardingCoordinator` that drive a multi-step onboarding flow
  with an app-namespaced completion store.
- Configurable onboarding window and minimum sizes plus
  `KikiOnboardingCloseDisposition` for explicit close semantics.
- Exact Settings-window registration through `kikiSettingsWindow(_:)`, used
  automatically by `KikiSettingsCoordinatorView`.

### Changed

- `KikiSettingsWindowController` now tracks the exact SwiftUI Settings window
  registered by its view instead of scanning or mutating `NSApp.windows`.
- `KikiPaywallSheet` supports multiple secondary actions while preserving its
  single-secondary-action initializer.
- Compact and onboarding paywalls render messages, footnotes, and footer links
  together and share host-supplied action semantics.
- Empty onboarding step lists complete immediately instead of presenting an
  empty window.

### Removed

- The `KikiCommerce` target (and its `KikiCommerceTests`). Its types
  (`KikiProAccessManager`, `KikiProPlan`, `KikiProAccessConfiguration`,
  `KikiProPaywallSheet`, `KikiProUpgradeCard`, `KikiProStatusCard`, etc.)
  now live in the separate `KikiCommerceKit` package
  (`KikiCommerceCore` + `KikiRevenueCat` + `KikiCommercePresentation`).
  Replace `import KikiCommerce` with `import KikiCommerceCore` and
  `import KikiCommercePresentation` (and `import KikiRevenueCat` for the
  RevenueCat-backed `CommerceClient`).
- The `RevenueCatCommerceKit` package dependency. Apps that need the
  RevenueCat-backed `CommerceClient` now depend on `KikiCommerceKit`
  and `import KikiRevenueCat`.

### Migration

- 0.6 atom APIs remain available. Apps using the former `KikiCommerce` product
  must move imports and dependencies to `KikiCommerceKit`; see
  `Docs/KikiCommerce.md`.

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
