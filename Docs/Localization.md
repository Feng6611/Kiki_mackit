# Kiki Localization

Kiki_mackit does not ship its own localization catalog. All user-facing text
either travels through Kiki as caller-owned data, or resolves against the
host application's main bundle. This keeps the package mono-language on disk
and delegates every translation decision to the app that adopts it.

## Rule

Kiki is a UI + workflow library, not a copy library. The public surface
already reflects this — most types take copy through parameters
(`title: String`, `KikiOnboardingScaffold(title: ..., bodyText: ...)`,
`KikiAccessPaywallCopy`, ...). Callers are expected to pass strings that are
already localized on their side, typically via `String(localized: "…")` at the
construction site.

The three acceptable shapes, in preference order:

1. **Accept a `String` from the caller.** The library never wraps it,
   never looks it up, never rewrites it. This is the default for anything a
   product would want to customize (button titles, section headings, empty
   states, feature bullets, plan names, alert bodies). Callers pass a
   localized value in.

2. **Resolve from the caller's main bundle.** When Kiki must synthesize a
   string internally (composing an appName with a verb, deriving a
   permission label from a system authorization type, providing a sensible
   default the caller can drop-in), use
   `String(localized: "...", bundle: .main)`. The literal itself is the
   translation key; the app's `Localizable.xcstrings` provides translations.
   Every such site MUST document the exact key so downstream apps can add
   entries to their catalog.

3. **Ship a Kiki-owned string.** Only for text that has no product
   variability and where forcing every downstream app to translate it would
   duplicate work (rare — currently no cases). Would require adding
   `resources: [.process("Resources")]` to `Package.swift`, a
   `Sources/<module>/Resources/Localizable.xcstrings`, and
   `String(localized: "...", bundle: .module)`. Do not add this without a
   clear reason; caller-owned copy is almost always the right answer.

Avoid `NSLocalizedString`. Prefer `String(localized:)` — it is the modern
API, integrates with String Catalogs, and interpolates typed values.

Never format singular / plural with Swift string interpolation
(`"\(n) day\(n == 1 ? "" : "s") left"`). Use catalog `plural` variations via
`String(localized: "\(n) days left")` and let the catalog specify `one` /
`other` per locale.

Never concatenate translatable fragments (`String(localized: "Delete") + " "
+ name`). Each translatable unit must be a complete semantic phrase; use a
formatter placeholder such as `String(localized: "Delete \(name)")`.

## Caller responsibility

For every Kiki call that resolves a string from `bundle: .main`, the adopting
app is expected to add the exact source key to its `Localizable.xcstrings`
and translate it to every supported locale. Each Kiki module MUST list its
main-bundle keys in the module's `Docs/Kiki<Module>.md` under a
`Localization` heading — the app-side maintainer treats that list as a
required-key contract.

When Kiki proposes a default value the caller can override, both the
default and the override slot need translator coverage. Overrides win at
runtime, but the default remains as the fallback and should always render
in the app's UI language.

## Current status (2026-07-21)

The package currently uses zero `String(localized:)` calls, no
`bundle: .module` lookups, and no per-package catalog. Every user-facing
string is either passed through as caller-provided `String`, or emitted as
a plain English literal from inside the library.

The following list is the plain-English literals inside Kiki_mackit that
should move to `String(localized:, bundle: .main)` at the next Kit release.
Adopting apps should add matching keys to their `Localizable.xcstrings`
before the Kit ships those changes.

| Module | File / line | Current literal | Notes |
|---|---|---|---|
| KikiMenuBar | `KikiMenuBar.swift:63,120` | `"Quit \(appName)"` | Menu label. Key format: `Quit %@`. |
| KikiAuthorization | `KikiAuthorizationPanel.swift:20` | `"Screen Recording"` | Permission name; iterate through every `KikiAuthorizationKind` returning strings. |
| KikiAuthorization | `KikiAuthorizationAppDragSourceView.swift:16,109` | `"Drag me into the list"`, `"Drag upward"` | Drag hint and accessibility label. |
| KikiPaywall | `KikiPaywallPlanViews.swift:76` | `"Selected"`, `"Not selected"` | Accessibility value on paywall plan cards. |
| KikiSettings | `KikiSettingsApplications.swift:82` | `"Select an app..."` | Picker placeholder. Also fix `...` → `…`. |
| KikiSettings | `KikiAppMetadata.swift:188,197` | `"Terms of use"`, `"Privacy policy"` | Default About-pane link titles. |
| KikiSettings | `LaunchAtLogin.swift:75,130` | `"Launch at login"` | Default toggle label; already exposed as an override in the `.init(_ titleKey:)` overload. |
| KikiTriggerCorner | `KikiTriggerCorner.swift:16-22` | `"Top Left"` / `"Top Right"` / `"Bottom Left"` / `"Bottom Right"` | Enum descriptions used by Settings rows. |
| KikiOnboarding | `KikiOnboardingPermissionRow.swift:20` | `"Not connected"` | Default status label; already overridable via parameter. |

Suggested change shape (illustrative — do not apply in this repo without a
Kit release plan):

```swift
// KikiMenuBar.swift
case .quit(let appName, _):
    return String(
        localized: "Quit \(appName)",
        bundle: .main,
        comment: "Menu item. Callers must provide 'Quit %@' in their app's Localizable.xcstrings."
    )
```

After this change, an adopting app whose `Localizable.xcstrings` contains a
`Quit %@` key with ja/de/fr translations will render `Command Reopen を終了`
/ `Command Reopen beenden` / `Quitter Command Reopen` automatically. Apps
that do not translate the key see the English source, matching today's
behavior.

## Testing

Kiki tests should not assert on the English source of a caller-owned
`bundle: .main` string, because the resolved value depends on the test host
bundle and preferred language. Test the semantic path (which case fires,
which action runs) and let the string flow through as an opaque value.
