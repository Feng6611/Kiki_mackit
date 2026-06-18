# KikiCommerce

## Feature List

- `KikiProAccessManager`: shared Pro access state machine on top of
  `RevenueCatCommerceKit`.
- `KikiProPlan` and `KikiProPlanProduct`: app-provided plan metadata plus
  offering-resolved price and availability.
- `KikiProAccessStatus`: not started, trial, expired, and Pro states.
- `KikiTrialPolicy`: explicit start, auto start, or disabled trial policy.
- `KikiProAccessStorageKeys`: app-prefixed persistence keys for trial,
  onboarding, and debug override state.
- `KikiProPaywallSheet`: high-level sheet using `KikiPaywall` primitives.
- `KikiProStatusCard`, `KikiProUpgradeCard`-style composition through the
  high-level sheet.

## Technical Decisions

- `KikiCommerce` depends on `RevenueCatCommerceKit` and `KikiPaywall`.
- `KikiPaywall` does not depend on `KikiCommerce`; pure UI users should not be
  forced to link RevenueCat.
- Apps provide product IDs, copy, links, tint, app icon, and storage-key prefix.
- The manager owns configure, refresh, offering loading, explicit/auto trial,
  purchase, restore, onboarding completion, transaction refresh retry, and local
  debug override behavior.
- DEBUG override affects local app state and onboarding only. It does not forge
  RevenueCat receipts.

## Layout Contract

`KikiProPaywallSheet` sizes itself from presentation context:

- settings: 500 x 520
- onboarding: 560 x 620

Apps may pass a layout override for product-specific needs, but ordinary apps
should let the component choose the size. Footer links are sheet-level links:
`Restore Purchase`, optional `Terms`, and optional `Privacy`; Pro status cards
do not own footer links.

## App Adapter Guidance

When migrating an existing app, keep the app's public status and plan types as a
thin adapter first. Map app plans to `KikiProPlan`, create one
`KikiProAccessManager`, bind its published state back into the app's old
observable object, and move the paywall surface to `KikiProPaywallSheet`.

After call sites have stabilized, the app can gradually adopt the public Kiki
types directly.
