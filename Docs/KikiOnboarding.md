# KikiOnboarding

`KikiOnboarding` owns the reusable first-launch window for small macOS apps:
a SwiftUI scaffold view, a few row types, a permission row that binds to
`KikiAuthorization`, and a single-window controller built on `KikiWindow`.

Hosts own copy, persistence (`hasCompletedOnboarding`), completion semantics,
and any paid-access routing that follows onboarding. Kiki does not store
onboarding state and does not decide what happens after the user finishes.

## Visual Rules

- Default window size is `560 x 520`, matching the macOS Welcome shape used
  by Stage Manager, Continuity, and recent first-run dialogs.
- The primary action uses `.borderedProminent` and carries
  `.keyboardShortcut(.defaultAction)` so Return triggers it; the secondary
  action uses `.bordered` with no default shortcut.
- The header is `Image(systemName:)` framed in a rounded accent square plus
  a single H1 and an optional body paragraph. Custom artwork is not part of
  v1; hosts that need brand art compose atoms manually.
- Body rows stack vertically, capped at three for scannability. Rows use
  system images and follow the row spacing in `KikiSettings`.
- The permission row uses `KikiAuthorization` for state and routing; it
  never hardcodes the System Settings URL.

## Public API

- `KikiOnboardingScaffold`: full window content. Inputs: app name, title,
  optional body paragraph, rows, optional permission row, primary button,
  optional secondary button.
- `KikiOnboardingRow`: a single body row (`systemImage`, `title`, `detail`).
- `KikiOnboardingPermissionRow`: permission row bound to a
  `KikiAuthorizationPanel` plus host instruction text. It refreshes when the
  app becomes active so the row reflects user changes in System Settings.
- `KikiOnboardingAction`: title plus closure, shared by primary and secondary.
- `KikiOnboardingWindowController`: single-instance window built on
  `KikiSingleWindowController.utility(...)` with a stable frame autosave
  name and an `onClose` closure.

## Boundaries

KikiOnboarding may:

- own the welcome window chrome, scaffold layout, row visuals, and
  permission row plumbing;
- provide a single-window controller that closes on Done and stays single
  instance.

KikiOnboarding must not:

- store `hasCompletedOnboarding` or any persistence;
- decide what the next surface after onboarding is;
- own paid-access routing, trial start, or restore-purchase decisions;
- hardcode product copy beyond safe defaults.
