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
  restores the autosaved frame for the Settings window.
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

Menu bar hosts call `openForMenuBarApp()` so the window controller has a
chance to prepare the app activation state and to restore the autosaved
frame after AppKit presents the scene.

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
- Restores the autosaved frame and applies `contentMinSize` after the
  scene is presented.
- Reports `isVisible` by searching `NSApp.windows` for a window with the
  matching `frameAutosaveName`. Title matching is no longer used.

## Removed in 0.6.0

- `KikiSettingsUI` namespace and its `FormPane`, `LinkButton`, `CopyRow`
  shims and the `AppIdentityView`, `ApplicationRow`, `ApplicationPicker`
  type aliases. Use `KikiSettingsPane`, `KikiSettingsLinkRow`,
  `KikiSettingsCopyRow`, `KikiAppIdentityView`,
  `KikiSettingsApplicationRow`, and `KikiSettingsApplicationPicker`.

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
