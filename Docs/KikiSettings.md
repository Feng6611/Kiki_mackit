# KikiSettings

The host owns its Settings scene, tabs, values, copy and actions. Kiki provides
window registration, navigation, grouped forms and reusable rows.

## Default integration

Create a KikiSettingsWindowLayout and pass it to
KikiSettingsWindowController(frameAutosaveName:layout:). Supply that controller
to KikiSettingsCoordinator, then render KikiSettingsCoordinatorView inside the
host's native Settings scene. The view inherits the controller's layout; explicit
legacy size arguments still work. New code should configure sizes once.

Defaults are 500×620 ideal, 500×480 minimum, 500×780 maximum. Bounds are
normalized by KikiSettingsWindowLayout. The registered NSWindow owns frame
restoration; saved sizes outside supported bounds reset to the ideal.
KikiSettingsCoordinator.close() targets that window, not unrelated app windows.

SwiftUI callers can use the native openSettings action. AppKit callers use
KikiSettingsOpener: it invokes the standard Settings menu item first, then the
tracked showSettingsWindow: selector fallback. See APIConventions.md.

## Panes and rows

KikiSettingsPane is a grouped Form with top alignment. KikiSettingsShell is
the lower-level TabView escape path. Neither adds mandatory product settings.

Rows accept caller-owned bindings and localized strings:
toggle, value, slider, stepper, menu picker, segmented picker, status,
authorization, application, link, copy and helper text.

Adaptive segmented pickers use option count and available width. Long labels
fall back to the native menu; explicit segmented/menu preferences remain available.
Copy rows show a short checkmark and copiedTitle after a successful pasteboard
write. Link rows accept an optional action without changing their content.

## About

KikiStandardAboutPane accepts metadata, links, tint and onOpenLink together.
URL interception applies only to link rows and preserves the displayed value;
copy rows retain their native action.

The optional accessStatus renders title, subtitle, action and loading feedback
through KikiAccessStatusCard. Neutral uses secondary styling; expired uses a
warning. The legacy access-state vocabulary is presentation compatibility only:
apps map product states, and new generic statuses can use KikiSettingsStatusRow
with neutral/success/warning/accent/info tones.

KikiAccessStatusRow is the compact form for About › Status: one row whose value
is the presentation title, styled by tone. Neutral (free tier, not started,
checking) is plain secondary text; trial shows `clock`; active and lifetime
show `crown.fill` (the crown means Pro, whatever the plan); expired shows a
warning. An action adds a chevron and makes the row a button. Put it in
statusContent instead of hand-building a status row, so every app shows
access the same way.

Extension slots:
- statusContent replaces the configured access content.
- additionalLinks inserts rows after standard links and before copyright.
- additionalSections appends sections within the same Form.

Repeated calls replace that slot; they do not append to earlier calls.
KikiAboutPane also supports additionalSections. Hosts retain control of
which sections exist.

## Launch at Login

`LaunchAtLogin.isEnabled` and `LaunchAtLogin.Toggle` are unchanged: `isEnabled`
means the item is actually enabled.

The pitfall: `SMAppService.mainApp.register()` can succeed and leave the item
in `.requiresApproval`. macOS holds it until the person allows it in System
Settings › Login Items and shows no prompt, so `isEnabled` reads false and a
plain toggle snaps back with no explanation. Use the approval-aware API instead.

- `LaunchAtLogin.status` → `LaunchAtLoginStatus` (`enabled`, `requiresApproval`,
  `notRegistered`, `notFound`, `unknown`).
- `LaunchAtLogin.setEnabled(_:)` → `LaunchAtLoginOutcome` (`enabled`,
  `requiresApproval`, `disabled`, `failed(message:)`). It classifies from the
  status read back after the call; a thrown error while enabling is `failed`.
  Enabling an already-enabled item does nothing, and there is no
  unregister-then-register, which would switch a working item off if the second
  call failed.
- `LaunchAtLogin.openSystemSettingsLoginItems()` opens Login Items.
- `KikiLaunchAtLoginModel` (`@MainActor ObservableObject`) publishes `status`,
  offers `set(_:)`, `refresh()` and `isOn`, and refreshes when the app becomes
  active again. `isOn` is true for `.enabled` and `.requiresApproval`: the
  request is made and pending, so the switch stays on and the row explains it.
  It takes a `LaunchAtLoginService` (status, register, unregister) so tests use
  a fake; the default is `SMAppService.mainApp`.
- `KikiSettingsLaunchAtLoginRow(title:systemImage:approvalNote:openLoginItemsTitle:model:)`
  is a `KikiSettingsToggleRow` that, while `.requiresApproval`, adds the note as
  helper text and a borderless button to Login Items. A failed request only
  reverts the switch; read the outcome from `model.set(_:)` to react.

Hosts provide, already localized: the row title, `approvalNote` (for example
"Allow it in System Settings › Login Items to finish."), and
`openLoginItemsTitle`. Keep the model in a `@StateObject`.

## Localization

All explicit text parameters are already-localized caller values.
KikiSettingsCopyRow's fallback key is `Copied` in the main bundle; pass
copiedTitle for an app-owned live language setting.
Other main-bundle defaults: `Terms of use`, `Privacy policy`,
`Launch at login` (see the corresponding source defaults).
Keep the host catalog in sync with the defaults it uses.

## Verification

Package hosting tests cover registration, shared geometry, slot order and
replacement, single mounting, and link/copy routing.
Use the Component Gallery for long text, narrow windows, loading, keyboard
navigation, VoiceOver and system Reduce Motion.
