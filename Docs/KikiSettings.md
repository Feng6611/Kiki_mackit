# KikiSettings

## Feature List

- `KikiSettingsShell`: top-tab SwiftUI settings shell for use inside a native `Settings {}` scene.
- `KikiSettingsTabSpec`: app-owned tab metadata (`tab`, `title`, `systemImage`) consumed by the shell.
- `KikiSettingsPane`: grouped `Form` pane chrome with standard scene padding and top alignment.
- `KikiAboutPane`: reusable app identity, status, and links layout based on Command Reopen's About settings.
- `KikiSettingsValueRow`, `KikiSettingsStatusRow`, `KikiSettingsToggleRow`,
  `KikiSettingsSegmentedPickerRow`, `KikiSettingsStepperRow`,
  `KikiSettingsSliderRow`, `KikiSettingsLinkRow`, `KikiSettingsCopyRow`, and
  `KikiSettingsHelperText` for common settings rows.
- Settings window activation, sizing, and frame autosave helpers.
- Settings opener that can either prepare the window itself or only trigger the Settings scene after app state is prepared.
- Menu bar app Settings helper that keeps accessory mode and avoids a Dock icon.
- Generic settings navigation model.
- Launch at Login state and toggle support for settings screens.
- App identity, application row, and running application picker components.

## Technical Decisions

- SwiftUI owns settings content because macOS settings screens are naturally form-driven; v1 intentionally stays on the native `Settings {}` scene instead of custom settings windows.
- The shell owns settings chrome, tab rendering, lazy pane creation, default dimensions, and common row language.
- Apps own tab definitions, business state, bindings, actions, and product-specific copy.
- Window dimensions have Command Reopen-inspired defaults (`540 x 560`) but remain app-overridable through `KikiSettingsShell(width:height:)` and `KikiSettingsWindowController(minimumContentSize:)`.
- AppKit remains responsible for window activation and autosaved frames.
- Menu bar apps should open Settings with `KikiSettingsOpener.openForMenuBarApp()`.
  It must keep the current activation policy and should not switch to `.regular`
  just to foreground Settings, because that creates a temporary Dock icon.
- Settings visuals may reuse `KikiDesign`, but Settings lifecycle stays tied to
  native `Settings {}` unless an app explicitly chooses a custom window scene.
- Window preparation and Settings scene opening stay separate so app adapters can inject business state before showing UI.
- Launch at Login lives in `KikiSettings` because it is a settings-screen concern for simple menu bar apps.
- `KikiSettingsUI` is kept only as a deprecated compatibility layer. New apps should use the shell and row components directly.

## Source Layout

- `KikiSettingsShell.swift`: defaults, tab specs, navigation model, and top-level shell.
- `KikiSettingsPane.swift`: pane chrome, helper text, spacing, and shared colors.
- `KikiSettingsRows.swift`: value, status, control, link, copy, and row
  label/content views.
- `KikiAboutPane.swift`: app identity and About pane layout.
- `KikiSettingsApplications.swift`: application row and running application picker.
- `KikiSettingsActions.swift`: public action wrapper for shared AppKit helpers.
- `KikiSettingsCompatibility.swift`: deprecated `KikiSettingsUI` shim.
- `KikiSettingsWindow.swift`: Settings scene window preparation and opening helpers.
- `LaunchAtLogin.swift`: login item state and toggle support.

## TODO & Checklist

- Keep Command Reopen-specific settings tabs in the app target.
- Keep product-specific access, paywall, onboarding, and analytics logic out of `KikiSettings`.
- Add more row types only after they appear in multiple apps or in the starter plus one real app.
- Before extracting to a standalone repo, validate API names against at least one starter app.
