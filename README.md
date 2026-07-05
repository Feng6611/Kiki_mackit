# Kiki_mackit

Reusable macOS app kit for small Kiki apps. It includes visual components,
AppKit bridge helpers, permission helpers, and reusable app workflow modules.
It intentionally contains no commerce SDK or paid-access state machine.

## Products

- `KikiSettings`: exact Settings-window registration, high-level coordination,
  navigation, standard About, and common settings rows.
- `KikiMenuBar`: `NSStatusItem` lifecycle and menu item model/controller.
- `KikiPaywall`: display-only paywall models, explicit action presentation, and
  compact/onboarding SwiftUI presets.
- `KikiDesign`: adaptive glass/material surface primitives shared across app surfaces.
- `KikiWindow`: AppKit window presenters and SwiftUI hosting utilities.
- `KikiOverlay`: non-interactive screen overlay feedback and Kiki material toasts.
- `KikiTriggerCorner`: reusable trigger-corner geometry, dwell state, and AppKit
  monitor for host-owned actions.
- `KikiAuthorization`: privacy-permission status helpers, System Settings
  routing, and a draggable app helper overlay for manual authorization.
- `KikiOnboarding`: first-launch coordinator, completion stores, close policy,
  scaffold/row atoms, permission row, and single-window controller.
- `KikiActivation`: activation-policy coordinator for menu bar apps that
  temporarily promote to a regular app.

## Repository Shape

Keep this package focused on reusable app infrastructure, not only reusable UI.
`Kiki_mackit` hosts two kinds of reusable modules:

- reusable macOS presentation and AppKit bridge surfaces such as Settings,
  menu bar, windows, overlays, and authorization helpers;
- reusable commerce-agnostic workflows such as Settings and Onboarding
  coordination, as long as the API stays product-agnostic.

Pure paywall presentation belongs in `KikiPaywall`. Provider-neutral paid
access and trial workflow belong in the optional, separate
`KikiCommerceKit`; RevenueCat transport is isolated in that package's
`KikiRevenueCat` target. Product-specific catalogs, grandfathering, unlock
rules, feature gates, and campaign policy stay in the app.

Use separate products for the UI surfaces:

- Apps can import only the modules they need.
- Xcode and SwiftPM can still resolve one remote package URL.
- Apps that do not sell anything never resolve or link a commerce package.

The package also contains an internal `KikiCore` target for small AppKit system
helpers shared by those products. It is intentionally not exposed as a library
product.

See [Docs/APIConventions.md](Docs/APIConventions.md) for public API boundaries
and extraction rules.

## Remote Usage

After pushing this package to a remote repository, consume it from another app with SwiftPM:

```swift
.package(url: "https://github.com/Feng6611/Kiki_mackit.git", from: "0.7.0")
```

Then add only the required products to the app target:

```swift
.product(name: "KikiSettings", package: "Kiki_mackit"),
.product(name: "KikiMenuBar", package: "Kiki_mackit"),
.product(name: "KikiPaywall", package: "Kiki_mackit"),
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
