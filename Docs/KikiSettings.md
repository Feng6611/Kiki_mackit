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

Extension slots:
- statusContent replaces the configured access content.
- additionalLinks inserts rows after standard links and before copyright.
- additionalSections appends sections within the same Form.

Repeated calls replace that slot; they do not append to earlier calls.
KikiAboutPane also supports additionalSections. Hosts retain control of
which sections exist.

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
