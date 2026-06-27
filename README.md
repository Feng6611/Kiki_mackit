# Kiki_mackit

Reusable macOS app kit for small Kiki apps. It includes visual components,
AppKit bridge helpers, permission helpers, and reusable paid-access workflow
modules for apps that share the same product mechanics.

## Products

- `KikiSettings`: settings window helpers, navigation model, and common settings UI rows.
- `KikiMenuBar`: `NSStatusItem` lifecycle and menu item model/controller.
- `KikiPaywall`: lightweight paywall models and SwiftUI presentation components.
- `KikiCommerce`: shared Pro access state machine and high-level paywall UI on
  top of `RevenueCatCommerceKit`.
- `KikiDesign`: adaptive glass/material surface primitives shared across app surfaces.
- `KikiWindow`: AppKit window presenters and SwiftUI hosting utilities.
- `KikiOverlay`: non-interactive screen overlay feedback and Kiki material toasts.
- `KikiTriggerCorner`: reusable trigger-corner geometry, dwell state, and AppKit
  monitor for host-owned actions.
- `KikiAuthorization`: privacy-permission status helpers, System Settings
  routing, and a draggable app helper overlay for manual authorization.
- `KikiOnboarding`: first-launch scaffold, row atoms, permission row, and
  single-window controller.
- `KikiActivation`: activation-policy coordinator for menu bar apps that
  temporarily promote to a regular app.

## Repository Shape

Keep this package focused on reusable app infrastructure, not only reusable UI.
`Kiki_mackit` is allowed to host two kinds of reusable modules:

- reusable macOS presentation and AppKit bridge surfaces such as Settings,
  menu bar, windows, overlays, and authorization helpers;
- reusable app-facing workflows such as paid-access state, trial handling,
  onboarding completion, and paywall composition, as long as the API stays
  product-agnostic.

Pure paywall presentation belongs in `KikiPaywall`. RevenueCat-backed purchase,
restore, trial, onboarding completion, and shared Pro access state belong in
`KikiCommerce`. Product-specific catalogs, grandfathering, unlock rules,
feature gates, and campaign policy still belong in the app.

Use separate products for the UI surfaces:

- Apps can import only the modules they need.
- Xcode and SwiftPM can still resolve one remote package URL.
- RevenueCat transport can evolve independently in `RevenueCatCommerceKit`,
  while `KikiCommerce` stays focused on reusable app-facing workflow.

The package also contains an internal `KikiCore` target for small AppKit system
helpers shared by those products. It is intentionally not exposed as a library
product.

See [Docs/APIConventions.md](Docs/APIConventions.md) for public API boundaries
and extraction rules.

## Remote Usage

After pushing this package to a remote repository, consume it from another app with SwiftPM:

```swift
.package(url: "https://github.com/Feng6611/Kiki_mackit.git", from: "0.6.0")
```

Then add only the required products to the app target:

```swift
.product(name: "KikiSettings", package: "Kiki_mackit"),
.product(name: "KikiMenuBar", package: "Kiki_mackit"),
.product(name: "KikiPaywall", package: "Kiki_mackit"),
.product(name: "KikiCommerce", package: "Kiki_mackit"),
.product(name: "KikiDesign", package: "Kiki_mackit"),
.product(name: "KikiWindow", package: "Kiki_mackit"),
.product(name: "KikiOverlay", package: "Kiki_mackit"),
.product(name: "KikiTriggerCorner", package: "Kiki_mackit"),
.product(name: "KikiAuthorization", package: "Kiki_mackit"),
.product(name: "KikiOnboarding", package: "Kiki_mackit"),
.product(name: "KikiActivation", package: "Kiki_mackit")
```

Local path development and product app dependency policy are workspace concerns;
keep those rules outside this package.

## References

`KikiAuthorization` is independently implemented for Kiki and inspired by
[zats/permiso](https://github.com/zats/permiso), which demonstrates a draggable
app helper for macOS privacy permission setup.
