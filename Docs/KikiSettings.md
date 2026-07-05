# KikiSettings

`KikiSettings` provides reusable Settings window and pane primitives for
small macOS apps. The host owns settings tabs, settings state, permission
meaning, and About content. Kiki owns chrome, row visuals, opener
mechanics, and window helpers.

## Public API

- `KikiSettingsShell`: top-tab SwiftUI shell that lives inside a native
  `Settings {}` scene. Keeps panes alive when switching tabs.
- `KikiSettingsTabSpec`: app-owned tab metadata (`tab`, `title`,
  `systemImage`) consumed by the shell.
- `KikiSettingsPane`: grouped `Form` pane chrome with top alignment.
- `KikiAboutPane`: app identity, status, and links layout for About panes.
- `KikiSettingsWindowController`: AppKit helper that activates the app and
  manages the exact Settings window registered by the SwiftUI scene.
- `KikiSettingsOpener`: imperative opener that triggers SwiftUI Settings
  through native paths first and a private selector only as a last resort.
- `KikiSettingsDefaults`: stable defaults for width, height, and minimum
  size.
- Rows:
  `KikiSettingsValueRow`, `KikiSettingsToggleRow`,
  `KikiSettingsSegmentedPickerRow`, `KikiSettingsMenuPickerRow`,
  `KikiSettingsStepperRow`, `KikiSettingsSliderRow`,
  `KikiSettingsStatusRow`, `KikiAuthorizationStatusRow`,
  `KikiSettingsLinkRow`, `KikiSettingsCopyRow`, and
  `KikiSettingsHelperText`.
- `LaunchAtLogin.Toggle`: minimal SwiftUI toggle on top of `SMAppService`.

## Opener Mechanics

`KikiSettingsOpener.open()` follows a native-first chain:

1. Trigger the standard `Settings...` (`Preferences...`) main-menu item
   that AppKit installs for the SwiftUI `Settings {}` scene. Found by
   `keyEquivalent == ","` first, then by normalized title.
2. If no menu item could be performed, fall back to
   `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)`
   and log a tracked message through
   `OSLog(subsystem: "kiki.mackit", category: "settings")` so the private
   path is visible in Console.

Menu bar hosts call `openForMenuBarApp()` so the window controller prepares
the app activation state. The registered SwiftUI view configures autosave and
minimum size when AppKit attaches it to the native Settings window.

`EnvironmentValues.openSettings` is the most native way to open Settings,
but it must be invoked from a SwiftUI view tree. `KikiSettingsOpener` is
AppKit-side and therefore prefers the main-menu route; hosts that already
sit inside SwiftUI should call `openSettings` from there directly.

## Pane Chrome

`KikiSettingsPane` is `Form` wrapped in `kikiSettingsPaneChrome()`. The
chrome is intentionally minimal:

```
formStyle(.grouped)
.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
```

The grouped form already paints the system Settings look. We do not stack
`scrollContentBackground(.hidden)`, custom backgrounds, or `scenePadding`;
those diverged from the native look. `KikiAboutPane` uses the same chrome.

## Picker Rows

Two picker rows ship with `KikiSettings`:

- `KikiSettingsSegmentedPickerRow`: two or three short, mutually exclusive
  options where direct comparison helps.
- `KikiSettingsMenuPickerRow`: three or more options, especially when the
  option labels are long enough to overflow a segmented control. Uses
  `.pickerStyle(.menu)`.

Hosts pick the row by option count and copy length per macOS HIG. Both
rows take a `Binding<Value>` and an `optionTitle` mapper, so the value type
stays app-owned.

## Window Controller

`KikiSettingsWindowController` does three things:

- Activates the app on `prepareForSettingsScene()` so a menu bar app can
  present the Settings window without losing focus.
- Restores the autosaved frame and applies `contentMinSize` to the exact native
  window registered by `kikiSettingsWindow(_:)`.
- Reports visibility and closes that registered window without searching or
  mutating unrelated `NSApp.windows`.

`KikiSettingsCoordinatorView` installs the registration bridge automatically.
Hosts composing `KikiSettingsShell` directly can apply
`.kikiSettingsWindow(windowController)` themselves.

## Removed in 0.6.0

- `KikiSettingsUI` namespace and its `FormPane`, `LinkButton`, `CopyRow`
  shims and the `AppIdentityView`, `ApplicationRow`, `ApplicationPicker`
  type aliases. Use `KikiSettingsPane`, `KikiSettingsLinkRow`,
  `KikiSettingsCopyRow`, `KikiAppIdentityView`,
  `KikiSettingsApplicationRow`, and `KikiSettingsApplicationPicker`.

## High-Level Features (0.7.0)

The atoms above stay; 0.7.0 adds optional presets that let the host skip
hand-wiring the most common Settings shapes.

- `KikiAppMetadata`: app identity (name, bundle id, short version, build,
  copyright) with `displayVersion` and a `KikiAppMetadata.bundle(.main)`
  factory that reads `Info.plist`. Pair with `KikiStandardAboutLinks` for
  ordered Website / Support / Feedback / Terms / Privacy rows.
- `KikiAccessStatusPresentation` + `KikiAccessStatusCard`: a small,
  Commerce-agnostic status card with a tone (`neutral | trial | active |
  expired`), title, optional subtitle, optional action title, and an
  in-flight flag. The host derives the presentation; the card stays
  unaware of RevenueCat or trial math.
- `KikiStandardAboutPane`: composes `KikiAboutPane` with an optional
  `KikiAccessStatusCard` and the ordered links from
  `KikiStandardAboutLinks`. One call covers the standard About pane.
- `KikiSettingsCoordinator<Tab>`: owns the
  `KikiSettingsNavigationModel`, the tab specs, an optional
  `KikiSettingsWindowController`, and a `KikiSettingsOpener`. Exposes
  `select(_:)`, `open(tab:isMenuBarApp:)`, `close()`, `prepare()`, and
  `isVisible`. `close()` acts only on the registered Settings window, so a
  menu bar host can dismiss Settings from an arbitrary trigger without owning
  or scanning global window state.
- `KikiSettingsCoordinatorView`: a thin SwiftUI wrapper that feeds the
  coordinator's selection into `KikiSettingsShell` so the host only
  supplies `@ViewBuilder content`.
- `KikiSettingsWindowController.close()`: closes the registered Settings
  window. Paired with `isVisible`, this lets hosts manage Settings dismissal
  imperatively.

These presets don't replace `KikiSettingsShell` — they sit on top of it and
remain Commerce-agnostic.

## Boundaries

KikiSettings may:

- own the Settings window opener, frame restore, and pane chrome;
- ship reusable rows for toggles, pickers, status, link, copy, sliders, and
  steppers;
- expose `LaunchAtLogin.Toggle` because `SMAppService` is awkward inline.

KikiSettings must not:

- own product-specific settings state;
- decide product copy for permission rows;
- host paywall, onboarding, or business workflow.
