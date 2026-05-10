# KikiSettings

## Feature List

- `KikiSettingsShell`: top-tab SwiftUI settings shell for use inside a native `Settings {}` scene.
- `KikiSettingsTabSpec`: app-owned tab metadata (`tab`, `title`, `systemImage`) consumed by the shell.
- `KikiSettingsPane`: grouped `Form` pane chrome with standard scene padding and top alignment.
- `KikiAboutPane`: reusable app identity, status, and links layout based on Command Reopen's About settings.
- `KikiSettingsStatusRow`, `KikiSettingsLinkRow`, `KikiSettingsCopyRow`, and `KikiSettingsHelperText` for common settings rows.
- Settings window activation, sizing, and frame autosave helpers.
- Settings opener that can either prepare the window itself or only trigger the Settings scene after app state is prepared.
- Generic settings navigation model.
- Launch at Login state and toggle support for settings screens.
- App identity, application row, and running application picker components.

## Technical Decisions

- SwiftUI owns settings content because macOS settings screens are naturally form-driven; v1 intentionally stays on the native `Settings {}` scene instead of custom settings windows.
- The shell owns settings chrome, tab rendering, lazy pane creation, default dimensions, and common row language.
- Apps own tab definitions, business state, bindings, actions, and product-specific copy.
- Window dimensions have Command Reopen-inspired defaults (`540 x 560`) but remain app-overridable through `KikiSettingsShell(width:height:)` and `KikiSettingsWindowController(minimumContentSize:)`.
- AppKit remains responsible for window activation and autosaved frames.
- Window preparation and Settings scene opening stay separate so app adapters can inject business state before showing UI.
- Launch at Login lives in `KikiSettings` because it is a settings-screen concern for simple menu bar apps.
- `KikiSettingsUI` is kept only as a deprecated compatibility layer. New apps should use the shell and row components directly.

## TODO & Checklist

- Keep Command Reopen-specific settings tabs in the app target.
- Keep product-specific access, paywall, onboarding, and analytics logic out of `KikiSettings`.
- Add more row types only after they appear in multiple apps or in the starter plus one real app.
- Before extracting to a standalone repo, validate API names against at least one starter app.
