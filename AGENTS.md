# Kiki_mackit

Reusable macOS UI, platform bridges and commerce-agnostic workflows.
Product copy, persistent keys, routing, distribution, entitlement policy and
application controllers stay in the host. Commerce workflow and RevenueCat
transport belong to the separate KikiCommerceKit package.

## Before editing

- Read Docs/APIConventions.md for public API and ownership rules.
- Read Docs/Localization.md before adding or changing visible strings.
- Read the affected Docs/Kiki<Module>.md; update its API and localization contract.
- README.md indexes products. Package.swift is the dependency source of truth.

## Implementation

- Prefer SwiftUI; keep AppKit bridges narrow and explicit.
- Features are the default integration entry; Atoms support demonstrated gaps.
  Implement Features with the same Atoms rather than parallel components.
- Accept caller-owned values, bindings and actions. Do not add a universal app shell.
- Keep KikiCore internal and small; never expose it as a public product.
- Keep Kiki_mackit free of Commerce SDKs, networking, analytics and product state.
- Name APIs by their role: Overlay is non-interactive, Window owns a window,
  Surface only draws chrome.
- Preserve source compatibility with inexpensive deprecated overloads when needed.
- Optional configuration must not introduce mandatory product settings.

## Verification

Run swift test and swift build -c release. For public API changes, compile the
Starter and affected downstream matrix according to ../BUILD_SYSTEM.md.
Use Examples/ComponentGallery for long copy, resizing, loading, disabled,
keyboard and accessibility checks. Keep real permissions and purchases manual.
Document migration in CHANGELOG.md; do not duplicate workspace release workflows.
