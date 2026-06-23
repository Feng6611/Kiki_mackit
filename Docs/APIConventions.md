# Kiki API Conventions

`Kiki_mackit` is an API package for business apps. It exposes reusable macOS
UI, AppKit bridge APIs, reusable app workflow APIs, and shared commerce
workflow APIs. It does not own product-specific business policy or app
architecture.

## Package Role

Kiki provides APIs for repeated Mac app mechanics and repeated small-app
workflow mechanics:

- menu bar status item hosting
- Settings shell and common rows
- single-window AppKit presentation for SwiftUI content
- paywall presentation primitives
- paid-access workflow on top of RevenueCatCommerceKit
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
- assumes a product-specific purchase provider outside `KikiCommerce`;
- hardcodes one app's feature gate, catalog, or campaign rule;
- hardcodes one app's onboarding routing or window flow;
- reaches into app-specific models or hardcoded storage keys;
- performs business routing after a button tap.

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

### KikiCommerce

Provides the shared paid-access state machine and high-level Pro paywall views
on top of `RevenueCatCommerceKit` and `KikiPaywall`. Apps provide plans,
storage keys, trial policy, product copy, links, and feature gating;
`KikiCommerce` owns configure, refresh, offerings, purchase, restore, trial
start, onboarding completion, and local debug override behavior.

This module is intentionally higher-level than `RevenueCatCommerceKit`.
`RevenueCatCommerceKit` owns provider transport and entitlement I/O.
`KikiCommerce` owns reusable app-facing workflow that multiple Kiki apps can
share.

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
- If the API touches RevenueCat or entitlement state, does it belong in
  `KikiCommerce` instead of `KikiPaywall` or another UI-only module?
- Is the public name based on the API role?
- Is the behavior covered by package tests?
- Does the README or module doc need an API note?
