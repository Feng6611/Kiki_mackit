# Kiki_mackit Agent Notes

This repository is a Swift package for reusable macOS app shell, UI, workflow,
and platform building blocks.

## Package Boundary

Keep this package focused on reusable macOS app infrastructure. Kiki should
make repeated AppKit/SwiftUI integration decisions and repeated small-app
workflow decisions stable, but product-specific behavior stays in the app.

Do not add product-specific business logic:

- Do not add Direct distribution logic.
- Do not add raw RevenueCat SDK transport outside the dedicated commerce
  boundary.
- Keep paid-access workflow and provider-specific purchase transport in the
  standalone `KikiCommerceKit` repository.
- Do not add app-specific copy, paywall policy, entitlement mapping,
  clipboard/history logic, analytics, networking, persistence, or distribution
  branching.

Kiki may include reusable commerce-agnostic workflows such as Settings and
Onboarding coordination. It must not regain a commerce target or SDK dependency.

Prefer small, package-local changes that preserve and clarify the public
surfaces of `KikiDesign`, `KikiWindow`, `KikiMenuBar`, `KikiSettings`,
`KikiPaywall`, `KikiOnboarding`, `KikiAuthorization`, `KikiOverlay`, and
`KikiTriggerCorner`.

Read `Docs/APIConventions.md` before changing public API. Kiki only exposes APIs
for business apps to call; adoption workflow, product skeletons, and app-specific
development practices belong in the workspace or starter, not in this package.

## Naming and API Design

Name modules and types by their design role, not by a loose product analogy.
Prefer precise component semantics over familiar but overloaded names.

- Use `Overlay` for non-interactive surfaces layered over the current screen or
  app content.
- Use `HUD` only for instrument-like heads-up displays that primarily present
  dense status or controls.
- Use `Toast` only for a compact temporary message surface.
- Use `Window` only when the component owns normal AppKit window presentation.
- Use `Surface` for reusable material/glass/chrome treatment without lifecycle.

Public Kiki APIs should expose design intent first and implementation detail
second. Prefer names such as `KikiScreenEdgeOverlayController` over generic
names such as `KikiHUDController` when the component is specifically a
screen-edge overlay.

When adding a component:

- Keep product copy, business state, colors with product meaning, and policy in
  the host app.
- Put reusable visual language, platform bridge behavior, defaults, and
  presentation types in Kiki.
- Provide semantic presets for common behavior, plus configuration for apps that
  need to tune copy, color, timing, and intensity.
- Avoid adding a new module if an existing module already owns the exact design
  role; add one when the role is distinct enough that the name clarifies the API.

## Component Roles

### KikiDesign

`KikiDesign` owns reusable visual surface primitives.

It should provide:

- Adaptive Liquid Glass/material fallback helpers.
- Material plus tint surface treatments.
- Foreground treatment for glass action labels.
- Small visual defaults that can be shared by Settings, MenuBar popovers, Paywall, sheets, and standalone windows.

It should not provide:

- Product-specific colors, copy, layout, state, menu content, settings tabs, window lifecycle, or purchase logic.

### KikiOverlay

`KikiOverlay` owns reusable non-interactive overlay presentation.

It should provide:

- Global screen-edge overlay feedback for transient or persistent app modes.
- Kiki material toast presentation paired with edge feedback.
- AppKit `NSPanel` lifecycle needed for all-Spaces, full-screen-compatible,
  non-activating overlays.
- Semantic presets for common mode transitions such as lock started, lock ended,
  and warning.
- Tunable style values for timing, intensity, material shape, glow depth, and
  panel level.

It should not provide:

- Product-specific status names, keyboard shortcuts, entitlement policy, or
  input-lock behavior.
- Interactive controls, normal windows, menu bar popovers, settings panes,
  analytics, networking, or persistence.

### KikiTriggerCorner

`KikiTriggerCorner` owns reusable macOS trigger-corner detection.

It should provide:

- User-facing corner choices.
- Multi-display corner geometry.
- Dwell, cooldown, and re-arm behavior.
- AppKit polling for `NSEvent.mouseLocation` and `NSScreen` frames.
- Test seams for pointer location, screen frames, and time.

It should not provide:

- Product-specific actions, access gating, analytics, persistence, onboarding,
  or entitlement policy.
- Input suppression, `CGEventTap` installation, hotkey registration, overlays,
  toast copy, or settings UI.

### KikiCore

`KikiCore` is an internal SwiftPM target for package-shared AppKit edge
helpers. It is not a public library product and should not grow into a general
utility layer.

It should provide:

- Package-private wrappers for repeated system actions used by multiple Kiki
  targets, such as opening URLs and activating the current app.

It should not provide:

- Public app-facing API, UI primitives, business logic, persistence, networking,
  analytics, or product-specific state.

### KikiWindow

`KikiWindow` owns AppKit window presentation infrastructure.

It should provide:

- Single-instance `NSWindow` presentation for SwiftUI content.
- Window configuration for size, minimum size, titlebar behavior, traffic-light visibility, frame autosave, and activation.
- Transparent window background bridging inspired by Binky/Dinky.

It should not provide:

- Menu bar popovers.
- Settings tab/content policy.
- Paywall purchase policy.
- Onboarding state machines or product-specific window flows.

### KikiSettings

`KikiSettings` owns the reusable Settings window shell for small macOS apps.

It should provide:

- SwiftUI `Settings {}` scene content wrappers.
- Top tab shell via `KikiSettingsShell`.
- Standard settings pane chrome via `KikiSettingsPane`.
- About pane structure via `KikiAboutPane`.
- Common rows such as status, link, copy, helper text, app identity, app picker
  rows.
- Default Settings window dimensions and AppKit opening helpers.
- Menu bar app Settings helper that opens the real SwiftUI Settings scene
  without switching the app to Dock-visible regular mode.
- Launch-at-login UI helpers for simple menu bar apps.

It should not provide:

- Product-specific tab definitions.
- Product-specific settings state.
- Pro/access/paywall policy.
- App-specific About copy, links, or status semantics.
- Split settings, custom window scene policy, or per-app window layout decisions unless exposed as optional configuration.

Apps should pass tabs, content, actions, links, and state into Kiki Settings APIs. Kiki supplies chrome and repeated row language.

### KikiMenuBar

`KikiMenuBar` owns reusable menu bar infrastructure.

It has two supported modes:

- Native `NSMenu` mode via `KikiMenuBarController` and `KikiMenuItem`.
- SwiftUI popover mode via `KikiMenuBarPopoverController`.

It should provide:

- `NSStatusItem` lifecycle management.
- Status item icon, tooltip, autosave name, and accessibility description.
- Status item active/inactive state and optional tint when an app needs one
  symbol to express two modes.
- Native menu item declaration for common menu semantics: action, toggle, link, status, settings, about, quit, separator.
- Standard shortcut expression via `KikiMenuShortcut`.
- SwiftUI popover hosting through `NSPopover` and `NSHostingController`.
- Popover size, behavior, show/close/toggle, and `onWillShow` refresh hook.

It should not provide:

- Product-specific menu ordering.
- Product-specific labels beyond safe defaults like `Settings...`, `About`, and `Quit <App>`.
- Business popover content, list rows, item models, send/copy/clear behavior, or app state.
- AirClip-specific clipboard UI or Command Reopen-specific access/pro logic.

For SwiftUI popovers, Kiki owns only the AppKit bridge. The app owns the SwiftUI view.

### KikiPaywall

`KikiPaywall` owns reusable paywall presentation primitives only.

It should provide:

- Sheet/content-level paywall chrome inspired by Command Reopen's sheet layout.
- Optional standalone paywall window presentation via `KikiPaywallWindowController`.
- Plan display models and lightweight reusable paywall UI.
- Feature rows, CTA layout, badges, and presentation structure that can be fed by app state.

It should not provide:

- Purchase transport.
- RevenueCat SDK calls.
- Entitlement refresh logic.
- Trial policy.
- App Store/direct distribution rules.
- Product IDs or pricing fetches.

Apps or a dedicated commerce package should adapt real commerce state into KikiPaywall display models.

## Public API Map

### `Sources/KikiSettings`

Primary API:

- `KikiSettingsDefaults`
- `KikiSettingsTabSpec`
- `KikiSettingsNavigationModel`
- `KikiSettingsShell`
- `KikiSettingsPane`
- `KikiAboutPane`
- `KikiAppIdentityView`
- `KikiSettingsHelperText`
- `KikiSettingsStatusRow`
- `KikiSettingsLinkRow`
- `KikiSettingsCopyRow`
- `KikiSettingsApplicationRow`
- `KikiSettingsApplicationPicker`
- `KikiSettingsWindowController`
- `KikiSettingsOpener`
- `LaunchAtLogin`

Compatibility:

- `KikiSettingsUI` is deprecated compatibility surface. Do not use it in new app code.

### `Sources/KikiMenuBar`

Primary API:

- `KikiMenuShortcut`
- `KikiMenuItem`
- `KikiMenuBarController`
- `KikiMenuBarPopoverController`
- `KikiMenuActions`

Compatibility:

- The old `KikiMenuItem.action(title:keyEquivalent:modifierMask:isEnabled:action:)` static helper is deprecated. New code should use `shortcut: KikiMenuShortcut?`.

### `Sources/KikiPaywall`

Primary API:

- `KikiPaywallDefaults`
- `KikiPaywallWindowController`
- `KikiPaywallShell`
- `KikiPaywallHeader`
- `KikiPaywallPlan`
- `KikiPaywallPlanCard`
- `KikiPaywallStatItem`
- `KikiPaywallFeatureRow`
- `KikiPaywallActionLabel`
- Any additional display-only paywall view/model types in this target.

Keep this target display-oriented. If an API needs network, receipt, entitlement, customer info, or product-fetching behavior, it belongs outside Kiki_mackit.

### `Sources/KikiOverlay`

Primary API:

- `KikiScreenEdgeOverlayBehavior`
- `KikiScreenEdgeOverlayMotion`
- `KikiScreenEdgeOverlayStyle`
- `KikiScreenEdgeOverlayPresentation`
- `KikiScreenEdgeOverlayPalette`
- `KikiScreenEdgeOverlayController`

Keep this target focused on non-interactive visual feedback overlays. If an API
needs app state, input policy, shortcut copy, or product-specific status
semantics, it belongs in the host app.

### `Sources/KikiTriggerCorner`

Primary API:

- `KikiTriggerCorner`
- `KikiTriggerCornerConfiguration`
- `KikiTriggerCornerMonitor`
- `KikiTriggerCornerGeometry`
- `KikiTriggerCornerActivationState`

Keep this target focused on detecting a dwell in a screen corner and invoking a
host-owned callback. If an API needs business policy, settings persistence,
input suppression, or visual feedback, it belongs in the host app or another
focused Kiki target.

### `Sources/KikiDesign`

Primary API:

- `KikiSurfaceDefaults`
- `KikiMaterialSurface`
- `View.kikiAdaptiveGlass(in:)`
- `View.kikiMaterialSurface(in:material:tint:tintOpacity:)`
- `View.kikiWindowMaterialBackground(material:tint:tintOpacity:)`
- `View.kikiGlassActionForeground()`

### `Sources/KikiWindow`

Primary API:

- `KikiWindowConfiguration`
- `KikiWindowButtonVisibility`
- `KikiTransparentWindowBackground`
- `View.kikiTransparentWindowBackground(...)`
- `KikiSingleWindowController`

## Directory Map

- `Sources/KikiCore`: package-private AppKit helpers shared by library targets.
- `Sources/KikiDesign`: Shared visual material/glass primitives.
- `Sources/KikiWindow`: AppKit window presenters and transparent window bridge.
- `Sources/KikiSettings`: Settings shell, rows, launch-at-login, settings window opening helpers.
- `Sources/KikiMenuBar`: Menu bar status item, native menu item model, SwiftUI popover controller.
- `Sources/KikiPaywall`: Paywall display components and display models.
- `Sources/KikiOverlay`: Non-interactive screen overlay presenters and display models.
- `Sources/KikiTriggerCorner`: Trigger-corner geometry, dwell state, and monitor.
- `Tests/KikiDesignTests`: Design API construction tests.
- `Tests/KikiWindowTests`: Window configuration and presenter construction tests.
- `Tests/KikiSettingsTests`: Settings API construction and state tests.
- `Tests/KikiMenuBarTests`: Menu item, shortcut, controller, and popover construction tests.
- `Tests/KikiPaywallTests`: Paywall display model tests.
- `Tests/KikiOverlayTests`: Overlay presentation and controller construction tests.
- `Tests/KikiTriggerCornerTests`: Trigger-corner geometry, activation, and monitor tests.
- `Docs`: Human-readable component notes. Update docs when public API or component boundaries change.

## Working Rules

- Use SwiftUI for reusable views and AppKit only for platform edges that SwiftUI does not model cleanly.
- Keep AppKit bridges narrow and explicit.
- Prefer semantic defaults, but let apps override sizes, links, titles, actions, and content.
- Add compatibility shims only when they prevent existing apps from breaking; mark them deprecated.
- When adding a public API, update the matching docs and tests.

Recommended verification:

- `swift test`
