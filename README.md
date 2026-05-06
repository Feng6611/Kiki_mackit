# Kiki_mackit

Reusable macOS menu bar app components for small Kiki apps.

## Products

- `KikiSettings`: settings window helpers, navigation model, and common settings UI rows.
- `KikiMenuBar`: `NSStatusItem` lifecycle and menu item model/controller.
- `KikiPaywall`: lightweight paywall models and SwiftUI presentation components.

## Repository Shape

Keep this package focused on reusable menu bar, settings, and paywall UI. Purchase transport, entitlement refresh, trial policy, and app access state belong outside this package.

Use separate products for the UI surfaces:

- Apps can import only the modules they need.
- Xcode and SwiftPM can still resolve one remote package URL.
- Commerce can evolve independently in `RevenueCatCommerceKit`.

## Remote Usage

After pushing this package to a remote repository, consume it from another app with SwiftPM:

```swift
.package(url: "https://github.com/Feng6611/Kiki_mackit.git", from: "0.2.0")
```

Then add only the required products to the app target:

```swift
.product(name: "KikiSettings", package: "Kiki_mackit"),
.product(name: "KikiMenuBar", package: "Kiki_mackit"),
.product(name: "KikiPaywall", package: "Kiki_mackit")
```

For local development, keep using the path dependency:

```swift
.package(path: "Packages/Kiki_mackit")
```

## Starter Follow-Up

The starter should depend on `Kiki_mackit` and own app-specific flow glue such as first launch, onboarding, entitlement store, settings tabs, menu labels, app links, and paywall plan configuration.

Apps that need RevenueCat should also depend on `RevenueCatCommerceKit`:

```swift
    .package(url: "https://github.com/Feng6611/RevenueCatCommerceKit.git", exact: "0.1.0")
```

Keep product-specific RevenueCat configuration, trial policy, app access state, and product-specific analytics in the host app or starter.
