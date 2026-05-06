# Kiki_mackit Agent Notes

This repository is a Swift package for reusable macOS UI building blocks.

Keep this package UI-only:

- Do not add Direct distribution logic.
- Do not add RevenueCat SDK wiring.
- Do not reintroduce a `RevenueCatCommerceKit` target here.
- Commerce belongs in the standalone `RevenueCatCommerceKit` repository.

Prefer small, package-local changes that preserve the public surfaces of `KikiMenuBar`, `KikiSettings`, and `KikiPaywall`.

Recommended verification after changes:

- `swift test`
