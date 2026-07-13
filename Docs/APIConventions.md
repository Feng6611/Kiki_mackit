# Kiki API Conventions

`Kiki_mackit` is an API package for business apps. It exposes reusable macOS
UI, AppKit bridge APIs, and commerce-agnostic app workflow APIs. It does not
own commerce workflow, product-specific business policy, or app architecture.

## Package Role

Kiki provides APIs for repeated Mac app mechanics and repeated small-app
workflow mechanics:

- menu bar status item hosting
- Settings shell and common rows
- single-window AppKit presentation for SwiftUI content
- paywall presentation primitives
- commerce-agnostic paywall presentation
- non-interactive overlay presentation
- trigger-corner detection
- privacy permission status and System Settings authorization helpers
- shared visual surface primitives

Business apps provide product meaning:

- app name, bundle id, links, and copy
- feature state and settings state
- product IDs, product copy, and access gates
- onboarding flow
- menu ordering and product-specific labels
- app-specific platform behavior

## Public API Rule

Every public Kiki type should be usable by a business app without importing
product knowledge.

Good API shape:

- accepts app-owned state through values or bindings;
- accepts app-owned actions through closures;
- accepts product copy from the caller;
- exposes stable configuration types;
- keeps AppKit lifecycle details hidden when that lifecycle is the reusable part;
- keeps reusable workflow state generic enough that multiple apps can adopt it
  with app-owned plans, copy, storage keys, and unlock rules.

Bad API shape:

- knows a product name;
- assumes or embeds any purchase provider;
- hardcodes one app's feature gate, catalog, or campaign rule;
- hardcodes one app's onboarding routing or window flow;
- reaches into app-specific models or hardcoded storage keys;
- performs business routing after a button tap.

## Native First Rule

Kiki must not re-wrap APIs that SwiftUI or AppKit already cover well. Hosts
should never have to choose between Kiki and a system API for the same job.

- SwiftUI `Settings` scene owns Settings window lifecycle on macOS 13+. Kiki
  only supplies pane chrome, rows, and a small opener. SwiftUI callers should
  prefer `EnvironmentValues.openSettings`, while AppKit-side `KikiSettingsOpener`
  prefers the standard `Settings...` main-menu item and only falls back to
  `showSettingsWindow:` as a last resort.
- SwiftUI `WindowGroup` and `Window` own standard windows. Use
  `KikiSingleWindowController` only for transparent backgrounds, non-standard
  style masks, hidden traffic-light buttons, or menu bar app utility windows
  where SwiftUI scenes do not provide what the host needs.
- `@AppStorage` owns small user defaults. Kiki does not provide a settings
  store abstraction.
- `LaunchAtLogin.Toggle` is allowed because `SMAppService` is awkward to use
  inline; the wrapper stays minimal.
- Where a Kiki bridge must reach for AppKit, the public API expresses intent
  (`KikiActivationPolicyCoordinator.begin(reason:)`) rather than mechanism
  (`setActivationPolicy(.regular)`).

## Feature-First API Layers

Every Kiki module exposes two layers:

- Feature presets are the default product-facing entry points. A normal App
  should begin with `KikiSettingsCoordinatorView`,
  `KikiOnboardingCoordinator`, `KikiCompactPaywall`, or
  `KikiOnboardingPaywall` rather than rebuilding their window, navigation,
  and action mechanics.
- Atoms are the advanced composition and escape layer. Examples include
  `KikiSettingsToggleRow`, `KikiPaywallFeatureRow`,
  `KikiOnboardingScaffold`, and `KikiOnboardingRow`.

Hosts following the default product shape should need only Feature presets plus
product content/configuration. Hosts with proven custom interaction or platform
requirements may compose Atoms. Feature presets must be implemented in terms of
Atoms in the same module so the two layers stay visually and behaviorally
consistent.

Kiki does not add a third, whole-App framework layer. App lifecycle,
`AppComposition`, routing, product Core, and product policy stay in the host.

## Compatibility Rule

Kiki is consumed by multiple independent App repositories. Before removing or
narrowing a public API:

- run package tests and API compatibility diagnostics;
- compile the Starter against the current checkout;
- compile the managed Product App matrix;
- deprecate an API before removal when a compatibility overload is cheap;
- record the migration path in the changelog.

Repository-local search is not proof that a public API has no callers. The
workspace matrix is the evidence source.

## Private API Fallback Rule

When Kiki must use a private selector, undocumented constraint, or other
non-public macOS detail to keep an API working, the module must:

- isolate the call to one named helper with a comment that links to the
  reason;
- guard the call behind a feature check or `try` so a future macOS can fall
  back without crashing;
- log a deprecation note when the private path is taken so regressions are
  visible;
- list the private path in this section so future audits know the surface.

Current private fallbacks tracked here:

- `KikiSettingsOpener` uses `NSApp.sendAction(Selector(("showSettingsWindow:")))`
  only after its AppKit-side standard main-menu `Settings...` lookup fails.
  SwiftUI callers should use `EnvironmentValues.openSettings` directly and do
  not need this fallback.

## Extraction Rule

Move code into Kiki only when the extracted piece becomes a reusable API, even
if the implementation includes state or workflow. Kiki is not limited to visual
components.

Extract when:

- the code removes repeated AppKit/SwiftUI bridge work;
- the code removes repeated small-app workflow or state-machine work;
- the behavior can be named without a product;
- the caller can provide copy, state, actions, colors, timing, and policy;
- the package can test the reusable behavior directly.

Do not extract when:

- only one app uses it;
- the behavior is tied to a product goal;
- the code decides what product feature needs access;
- the code owns product-specific access gates, grandfathering, or campaign
  routing;
- the code depends on a product-specific platform trick.

## Module Boundaries

### KikiSettings

Provides Settings window and pane APIs. Apps own settings tabs, settings state,
permission meaning, and About content.

### KikiMenuBar

Provides `NSStatusItem` lifecycle, native menu item mapping, and SwiftUI popover
hosting. Apps own menu ordering, labels, enabled state, and actions.

### KikiWindow

Provides AppKit window presentation and SwiftUI hosting. Apps own when a window
opens, what it contains, and what closing means.

### KikiPaywall

Provides paywall UI primitives only. It has no RevenueCat dependency. Apps or
commerce packages own product IDs, pricing, purchase, restore, trial, and
entitlement decisions.

### Commerce boundary

Commerce is not a Kiki_mackit module. The separate optional
`KikiCommerceKit` package owns provider-neutral access/trial workflow,
RevenueCat transport, and the adapter from commerce state to
`KikiPaywallPresentation`. Free apps depend only on Kiki_mackit.

### KikiOverlay

Provides non-interactive overlay presentation. Apps own what an overlay means
and when it appears.

### KikiTriggerCorner

Provides trigger-corner geometry, dwell, cooldown, and re-arm mechanics. Apps
own what action is triggered.

### KikiAuthorization

Provides privacy-permission status checks, System Settings routing, and a
draggable app helper overlay. Apps own why permission is needed, when to ask,
what failure means, and how recovery is routed.

### KikiOnboarding

Provides reusable first-launch coordination and window chrome: completion
stores, configuration and steps, a welcome scaffold, common row types, a
permission row that binds to `KikiAuthorization`, and a window controller built
on `KikiWindow`. Apps own the completion key, legacy-key migration, copy,
product-specific completion policy, and any paid-access routing.

### KikiActivation

Provides reusable activation-policy coordination for menu bar apps that
temporarily promote themselves to a regular app, then restore the previous
frontmost application. Apps own when to begin or end the promoted state and
what UI they install during it.

### KikiDesign

Provides reusable visual surface primitives and shared color tokens. Apps own
product color meaning and brand-specific layout.

### KikiCore

Internal only. Do not expose it as a product and do not grow it into a public
utility layer.

## Review Checklist

Before adding or changing public Kiki API:

- Can a business app call this without product-specific assumptions?
- Are all app-specific actions supplied by the caller?
- Are product copy and policy outside Kiki?
- If the API touches purchase transport, trial calculation, or entitlement
  state, does it belong in the separate `KikiCommerceKit` package instead of
  Kiki_mackit?
- Is the public name based on the API role?
- Is the behavior covered by package tests?
- Does the README or module doc need an API note?
