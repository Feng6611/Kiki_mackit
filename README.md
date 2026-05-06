# Kiki_mackit

Reusable macOS menu bar app components for small Kiki apps.

## Products

- `KikiSettings`: settings window helpers, navigation model, and common settings UI rows.
- `KikiMenuBar`: `NSStatusItem` lifecycle and menu item model/controller.
- `KikiPaywall`: lightweight paywall models and SwiftUI presentation components.

## Repository Shape

Keep these three products in one Swift package repository for now. They share the same platform floor, release cadence, and current validation app. Splitting into three repositories would add versioning and dependency overhead before the APIs have been proven in a second app.

Use separate products instead of separate repositories:

- Apps can import only the modules they need.
- Xcode and SwiftPM can still resolve one remote package URL.
- The modules can be split into separate repositories later without renaming public types.

## Remote Usage

After pushing this package to a remote repository, consume it from another app with SwiftPM:

```swift
.package(url: "https://github.com/Feng6611/Kiki_mackit.git", from: "0.1.0")
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

Create a separate starter repository after this package stabilizes. The starter should depend on `Kiki_mackit` and own app-specific flow glue such as first launch, onboarding, entitlement store, settings tabs, menu labels, app links, and paywall plan configuration.

Keep purchase providers, RevenueCat configuration, trial policy, app access state, and product-specific analytics out of this package.
