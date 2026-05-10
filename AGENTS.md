# Kiki_mackit Agent Notes

This repository is a Swift package for reusable macOS UI building blocks.

## Package Boundary

Keep this package focused on reusable macOS app shell and UI primitives. Kiki should make repeated AppKit/SwiftUI integration decisions stable, but product behavior stays in the app.

Do not add product-specific business logic:

- Do not add Direct distribution logic.
- Do not add RevenueCat SDK wiring.
- Do not reintroduce a `RevenueCatCommerceKit` target here.
- Commerce belongs in the standalone `RevenueCatCommerceKit` repository.
- Do not add app-specific copy, paywall policy, entitlement state, clipboard/history logic, analytics, networking, persistence, or distribution branching.

Prefer small, package-local changes that preserve and clarify the public surfaces of `KikiMenuBar`, `KikiSettings`, and `KikiPaywall`.

## Component Roles

### KikiSettings

`KikiSettings` owns the reusable Settings window shell for small macOS apps.

It should provide:

- SwiftUI `Settings {}` scene content wrappers.
- Top tab shell via `KikiSettingsShell`.
- Standard settings pane chrome via `KikiSettingsPane`.
- About pane structure via `KikiAboutPane`.
- Common rows such as status, link, copy, helper text, app identity, app picker rows.
- Default Settings window dimensions and AppKit open/restore helpers.
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

- Shell-level paywall chrome inspired by Command Reopen's sheet layout.
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
- `KikiPaywallShell`
- `KikiPaywallHeader`
- `KikiPaywallPlan`
- `KikiPaywallPlanCard`
- `KikiPaywallStatItem`
- `KikiPaywallFeatureRow`
- `KikiPaywallActionLabel`
- Any additional display-only paywall view/model types in this target.

Keep this target display-oriented. If an API needs network, receipt, entitlement, customer info, or product-fetching behavior, it belongs outside Kiki_mackit.

## Directory Map

- `Sources/KikiSettings`: Settings shell, rows, launch-at-login, settings window opening helpers.
- `Sources/KikiMenuBar`: Menu bar status item, native menu item model, SwiftUI popover controller.
- `Sources/KikiPaywall`: Paywall display components and display models.
- `Tests/KikiSettingsTests`: Settings API construction and state tests.
- `Tests/KikiMenuBarTests`: Menu item, shortcut, controller, and popover construction tests.
- `Tests/KikiPaywallTests`: Paywall display model tests.
- `Docs`: Human-readable component notes. Update docs when public API or component boundaries change.

## Working Rules

- Use SwiftUI for reusable views and AppKit only for platform edges that SwiftUI does not model cleanly.
- Keep AppKit bridges narrow and explicit.
- Prefer semantic defaults, but let apps override sizes, links, titles, actions, and content.
- Add compatibility shims only when they prevent existing apps from breaking; mark them deprecated.
- When adding a public API, update the matching docs and tests.

Recommended verification:

- `swift test`
