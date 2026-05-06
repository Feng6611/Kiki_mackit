# KikiSettings

## Feature List

- Settings window activation, sizing, and frame autosave helpers.
- Settings opener that can either prepare the window itself or only trigger the Settings scene after app state is prepared.
- Generic settings navigation model.
- Native-first SwiftUI form pane and reusable settings rows.
- Launch at Login state and toggle support for settings screens.
- App identity, link, copy, application row, and running application picker components.

## Technical Decisions

- SwiftUI owns settings content because macOS settings screens are naturally form-driven.
- AppKit remains responsible for window activation and autosaved frames.
- Window preparation and Settings scene opening stay separate so app adapters can inject business state before showing UI.
- Launch at Login lives in `KikiSettings` because it is a settings-screen concern for simple menu bar apps.
- Business tabs and state are injected by the app instead of living in this module.

## TODO & Checklist

- Keep Command Reopen-specific settings tabs in the app target.
- Add more row types only after they appear in multiple apps.
- Before extracting to a standalone repo, validate API names against at least one starter app.
