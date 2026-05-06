# KikiPaywall

## Feature List

- Lightweight paywall plan model.
- Reusable plan card, feature row, stat item, and action label views.
- Loading, disabled, selected, and unavailable visual states.

## Technical Decisions

- SwiftUI-only because this module is presentation-focused.
- No RevenueCat dependency; purchasing and entitlement policy belong to app code.
- This first version extracts stable UI atoms rather than a full paywall flow.

## TODO & Checklist

- Add a store protocol only after two apps need the same purchase flow shape.
- Keep trial, grandfathering, product ids, and access gating outside this module.
- Validate visual parity in Command Reopen after replacing local private components.
