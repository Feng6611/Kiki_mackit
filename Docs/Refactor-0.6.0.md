# Kiki_mackit 0.6.0 Refactor Plan

## Goal

Make `Kiki_mackit` a real general-purpose macOS component library so that a
host app that already adopts `Kiki_menubar_starter` can ship by writing
business logic only. Native first, AppKit + SwiftUI, no hand-rolled chrome
where the system already provides something good. All changes ship as a
single 0.6.0 release; intermediate versions are not produced.

The reference host is `mac-hidden-dot`. Every API motion in this plan must
let Hidden Dot keep the same product behavior with strictly less product
side code, and let `Kiki_menubar_starter` expose a smaller business-only
surface for new apps.

## Review Findings From The 0.5 Surface

1. `KikiSettings` opener is reasonable but still searches windows by title
   substring and double-dispatches `prepareForSettingsScene` for menu bar
   apps. The chain (`EnvironmentValues.openSettings` first, then main-menu
   item, then private selector as a last resort) is documented but not
   reflected in code or in logs. A long-list menu picker row is missing,
   so hosts hand-roll `Picker` rows in Settings panes.
2. `KikiMenuBar` already exposes the right item types, but `makeMenu` is
   coupled to `KikiMenuBarController`. Hidden Dot owns its own
   `NSStatusItem` so it cannot reuse `KikiMenuItem` semantics; it
   re-implements the AppKit menu mapping by hand. A deprecated
   `keyEquivalent:modifierMask:` overload still lives on `KikiMenuItem`.
3. `KikiAuthorization` overlay tracks the System Settings window with a
   `0.18s` repeating `Timer`. This burns a runloop wakeup forever after
   `present(...)`. AX move/resize observers cover the same need natively.
4. `MenuBarSpaceController` in
   `mac-hidden-dot/HiddenDot/App/HiddenDotApp.swift` does five reusable
   things at once: activation-policy bookkeeping, Dock prewarm,
   frontmost-app capture/restore, compact main-menu install, and reveal
   lifecycle. The first three belong to Kiki; the last two are product
   code.
5. Onboarding is duplicated between `HiddenDotOnboardingView.swift` and
   `StarterOnboardingView.swift`. Both run the same scaffold layout, the
   same row visuals, and the same `KikiSingleWindowController` plumbing.
   This is the largest "host should not write" surface today.
6. `KikiPaywall` exposes the right atoms but no one-call preset, so the
   starter and Hidden Dot rebuild the same paywall sheet layout.
7. `KikiOverlay` style has 25 public init parameters. A host can pick any
   combination and break the Kiki visual rhythm. Hosts should not pick a
   palette by hand; tone should drive color.
8. `KikiSettingsPane` chrome stacks `formStyle(.grouped)`,
   `scrollContentBackground(.hidden)`, a custom `windowBackgroundColor`,
   and `scenePadding`. The result diverges from the system Settings look
   that `.grouped` already produces.
9. `KikiSettingsUI` (`Sources/KikiSettings/KikiSettingsCompatibility.swift`)
   is a deprecated wrapper namespace left over from 0.4. Nothing in the
   kit or the starter targets it anymore.

## Module-By-Module Plan

All boundary moves are documented in the module docs. This section is the
implementation map.

### 1. KikiSettings

`KikiSettingsOpener.open()`
- Keep the main-menu lookup as the first step.
- Log a tracked "private selector fallback" message through
  `OSLog(subsystem: "kiki.mackit", category: "settings")` when the private
  selector fires, so regressions are visible in Console.
- Merge the duplicate `prepareForSettingsScene` dispatch in
  `openForMenuBarApp(...)`. One call is enough.

`KikiSettingsWindowController.visibleSettingsWindows(...)`
- Match strictly by `frameAutosaveName`. Drop the title substring fallback;
  hosts already pass the autosave name in init.

`KikiSettingsPane.kikiSettingsPaneChrome()`
- Collapse to `formStyle(.grouped)` plus
  `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)`.
- Remove `scrollContentBackground(.hidden)`, the custom
  `windowBackgroundColor`, and `scenePadding`. SwiftUI grouped form already
  draws the standard look.
- `KikiAboutPane` keeps the same chrome modifier.

`KikiSettingsRows`
- Add `KikiSettingsMenuPickerRow<Value>` for enumerated settings with three
  or more options. Mirrors `KikiSettingsSegmentedPickerRow` but uses
  `.pickerStyle(.menu)`. Hosts choose by option count and copy length per
  macOS HIG.

Removals
- Delete `Sources/KikiSettings/KikiSettingsCompatibility.swift`
  (`KikiSettingsUI`).

### 2. KikiMenuBar

- Extract `public enum KikiMenuBuilder` with
  `@MainActor public static func menu(from items: [KikiMenuItem], title: String) -> NSMenu`
  from the current body of `KikiMenuBarController.makeMenu()`. The
  controller becomes a thin caller. Hosts that own their own `NSStatusItem`
  call `KikiMenuBuilder.menu(from:title:)` from their click handler.
- Remove the deprecated
  `KikiMenuItem.action(title:keyEquivalent:modifierMask:isEnabled:action:)`
  extension. The shortcut-bearing variant is the only path.

### 3. KikiAuthorization

`KikiAuthorizationAssistant`
- Remove `trackingTimer`. Install AX observers (`AXObserverCreate` plus
  `AXObserverAddNotification` for `kAXMovedNotification`,
  `kAXResizedNotification`, `kAXWindowMovedNotification`, and
  `kAXWindowResizedNotification`) on the System Settings process when it
  becomes frontmost.
- Keep `NSWorkspace.didActivateApplicationNotification` so we re-anchor on
  app activation changes.
- Add an `NSApplication.didChangeScreenParametersNotification` listener so
  the overlay re-anchors after display layout changes.
- Tear down all observers in `dismiss()`.
- If AX observer creation fails (Accessibility not granted), fall back to
  the one-shot positioning during initial present and rely on the
  workspace notification only.

### 4. KikiActivation (new module)

Sources
- `Sources/KikiActivation/KikiActivationPolicyCoordinator.swift`:
  `@MainActor public final class KikiActivationPolicyCoordinator`.
  - `init(prewarmsThroughDockOnFirstActivation: Bool = false, logger: KikiActivationLogger? = nil)`.
  - `start()`: install `.accessory` and log the initial state.
  - `begin(reason:)`: capture the current frontmost app (if not us),
    optionally Dock-prewarm on first call, switch to `.regular`, and
    activate via `activate(from:)` on macOS 14+ or
    `activate(ignoringOtherApps:)` on macOS 13.
  - `end()`: restore the previously captured frontmost app via
    `yieldActivation(to:)` plus `activate(from:)` on macOS 14+, or
    `activate(options:)` on macOS 13; then reset the policy to `.accessory`.
  - `reset(toPolicy:reason:)`: apply a policy without restoring a previous
    app, used when a setting toggle cancels the promoted state.
- `Sources/KikiActivation/KikiActivationLogger.swift`: protocol plus
  default `OSLog` implementation in category `kiki.activation`.

Boundaries
- The coordinator does not install or restore `NSApp.mainMenu`. The host
  owns its compact menu.
- The coordinator does not gate `begin` by host policy (multi-display,
  feature flag, etc.). The host gates and then calls.

Tests
- `Tests/KikiActivationTests`: construction, idempotent `start`, `begin`
  capturing `nil` when the frontmost is the current process, and
  `reset(toPolicy:)` not consulting the previous app. No real policy
  switching or activation; bookkeeping only.

### 5. KikiOnboarding (new module)

Sources
- `Sources/KikiOnboarding/KikiOnboardingScaffold.swift`: SwiftUI view,
  `560 x 520`. Header is `Image(systemName:)` in an accent rounded square
  plus title and optional body. Rows stack vertically (cap at three for
  scannability). Optional permission row at the bottom of the row stack.
  Primary action `.borderedProminent` plus
  `.keyboardShortcut(.defaultAction)`; optional secondary action
  `.bordered`.
- `Sources/KikiOnboarding/KikiOnboardingRow.swift`: `(systemImage, title,
  detail)` struct and view.
- `Sources/KikiOnboarding/KikiOnboardingPermissionRow.swift`: binds to a
  `KikiAuthorizationPanel`, exposes instruction text, opens the assistant
  on tap, and refreshes on `NSApplication.didBecomeActiveNotification`.
- `Sources/KikiOnboarding/KikiOnboardingAction.swift`:
  `struct KikiOnboardingAction { let title: String; let action: () -> Void }`.
- `Sources/KikiOnboarding/KikiOnboardingWindowController.swift`: wraps
  `KikiSingleWindowController.utility(...)` with a stable frame autosave
  name and an `onClose` closure.

Boundaries
- The module does not own `hasCompletedOnboarding` persistence; the host
  owns it.
- The module does not run paid access, trial start, or "what comes next".

Tests
- `Tests/KikiOnboardingTests`: construction tests for the scaffold and the
  window controller. SwiftUI rendering stays exercised in host apps.

### 6. KikiPaywall

- Add `KikiPaywallSheet` preset view in
  `Sources/KikiPaywall/KikiPaywall.swift`. Inputs are small config structs
  so the host writes data, not layout:
  - `KikiPaywallHeaderConfig(title:, subtitle:, icon:)`
  - `KikiPaywallStatConfig(value:, label:)`
  - `KikiPaywallActionConfig(title:, isLoading:, isEnabled:, action:)`
- The sheet composes `KikiPaywallShell` internally so atom users keep
  visual parity with the preset.
- Refactor `KikiCommerce.KikiProPaywallSheet` to compose `KikiPaywallSheet`
  (or share its inner view) so the commerce variant inherits future visual
  changes for free.

### 7. KikiOverlay

- Make most of `KikiScreenEdgeOverlayStyle`'s init parameters internal.
  Public init keeps four knobs: `glowIntensity`, `toastWidth`, `panelLevel`,
  `toastDuration`. `.default` and `.screenEdge(glowIntensity:)` remain.
- Add `public enum KikiOverlayTone { case alert, success, warning }`.
  Each tone maps internally to a `(tint, companionTint)` pair from the
  current palette.
- `KikiScreenEdgeOverlayPresentation.lockStarted/.lockEnded/.warning` add a
  `tone:` parameter that defaults to today's visual.
- Demote `KikiScreenEdgeOverlayPalette` to `internal`. Hosts that need a
  custom color still pass `tint:`/`companionTint:` directly to the factory.

Downstream impact
- `build/mac-cat-keyboard-lock/CatKeyboardLock/Shared/CatKeyboardLockOverlayPresentations.swift`
  calls `KikiScreenEdgeOverlayStyle.style(for:)` (does not exist in 0.5
  source, but the file references the style ctor). Track follow-up in
  CatKeyboardLock after this release lands.

## Cross-Cutting Conventions Touched

- `Native First Rule` in `Docs/APIConventions.md` now applies to every new
  surface added in 0.6.0. New code that re-wraps SwiftUI/AppKit APIs that
  already do the job is rejected.
- `Two API Layers` (Atoms + Presets) is the shape every module ships in.
  `KikiPaywallSheet`, `KikiOnboardingScaffold`,
  `KikiScreenEdgeOverlayPresentation` factories are the presets;
  `KikiPaywallShell`, `KikiOnboardingRow`, `KikiScreenEdgeOverlayController`
  are the atoms.
- `Private API Fallback Rule` lists the one private path used in
  `KikiSettings`. No other module uses private API.

## Out-Of-Scope For 0.6.0

- Migrating `mac-hidden-dot` and `mac-cat-keyboard-lock` to the new APIs.
  Host migration is its own release per app.
- Splitting `KikiCommerce` further. The current shape is fine; only
  `KikiProPaywallSheet` is touched to track the new `KikiPaywallSheet`.
- Replacing `KikiSingleWindowController` with a SwiftUI `Window` scene
  helper. `KikiWindow.md` already documents the choice; no code change.
- A formal `KikiSettingsLogger` protocol. The settings opener uses
  `OSLog` directly with a stable subsystem string.

## Order Of Execution

1. Rewrite `Docs/KikiSettings.md` (deleted in working tree).
2. KikiSettings code changes.
3. KikiMenuBar extraction and removal.
4. KikiAuthorization assistant rewrite.
5. KikiActivation new module.
6. KikiOnboarding new module.
7. KikiPaywall sheet preset and KikiCommerce sheet refactor.
8. KikiOverlay narrowing.
9. Tests: update existing tests, add new module tests.
10. `swift test` from `build/Kiki_mackit`.

## Verification

- `swift test` must pass for all targets.
- `KikiActivationTests` and `KikiOnboardingTests` exist with at least
  smoke-level coverage.
- `KikiMenuBuilder.menu(from:title:)` is unit-tested with the same
  fixtures used by `KikiMenuBarController`.
- `KikiAuthorizationAssistant` no longer references `Timer`.
- `KikiSettingsCompatibility.swift` is gone.
- Public symbols match `CHANGELOG.md` 0.6.0 entries.
