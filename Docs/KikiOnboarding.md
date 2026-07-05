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
  instance;
- track step navigation when the host opts into the 0.7.0 coordinator
  (see below).

KikiOnboarding must not:

- store `hasCompletedOnboarding` or any persistence;
- decide what the next surface after onboarding is;
- own paid-access routing, trial start, or restore-purchase decisions;
- hardcode product copy beyond safe defaults.

## High-Level Features (0.7.0)

The scaffold atom stays; 0.7.0 adds a small declarative coordinator for
hosts that want a multi-step welcome flow without rolling their own state
machine.

- `KikiOnboardingStep`: a four-case enum (`.welcome | .features |
  .permission | .success`) plus `.paywallHandoff` (Commerce-agnostic) and
  `.custom(id:view:)`. Each non-handoff case carries a typed content
  struct (`KikiOnboardingWelcomeContent`, etc.) describing copy and the
  primary/secondary button titles. The `custom` view builder receives a
  `KikiOnboardingNavigation` so it can drive `advance` / `back` / `skip` /
  `finish` without capturing the coordinator itself.
- `KikiOnboardingNavigation`: a small struct of `@MainActor` closures
  (`advance`, `back`, `skip`, `finish`) built by the coordinator and
  handed to custom step views. Narrowing navigation to these four actions
  keeps custom steps decoupled from the coordinator's internal state.
- `KikiOnboardingConfiguration`: the step list together with `appName`,
  `tint`, `canSkip`, `completionKey`, window autosave name, and window
  title. `canSkip` defaults to `false`; flip it to `true` to enable
  coordinator-level `skip()` and surface `canSkip` to custom views.
- `KikiOnboardingCompletionStore`: protocol backed by
  `KikiOnboardingUserDefaultsCompletionStore` (production) and
  `KikiOnboardingInMemoryCompletionStore` (tests/previews). Lets the host
  own the completion-key namespace without forcing UserDefaults.
- `KikiOnboardingCoordinator`: `@MainActor` ObservableObject that drives
  step navigation (`startIfNeeded`, `advance`, `back`, `skip`, `finish`,
  `resetCompletion`), opens and closes the onboarding window, and routes
  `.paywallHandoff` to a host-supplied closure (or auto-advances if the
  closure is nil). `skip()` is a guarded no-op when `canSkip` is false;
  when allowed, it commits completion via `finish()`.

The coordinator never imports Commerce: the host wires the paywall handoff
closure to whichever paywall surface it chose (`KikiCompactPaywall`,
`KikiOnboardingPaywall`, or a custom view).
