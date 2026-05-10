# KikiPaywall

## Feature List

- Lightweight paywall plan model.
- Reusable paywall sheet shell and header.
- Reusable plan card, feature row, stat item, and action label views.
- Loading, disabled, selected, and unavailable visual states.

## Technical Decisions

- SwiftUI-only because this module is presentation-focused.
- No RevenueCat dependency; purchasing and entitlement policy belong to app code.
- `KikiPaywallShell` extracts the stable sheet structure from Command Reopen:
  scrollable header/content, fixed action/footer area, optional close button,
  default sheet sizes, and subtle native background.
- The shell is not a full purchase flow. The host app supplies content, action
  buttons, footer links, loading state, close behavior, and all side effects.
- Dismissal policy belongs to the host app. `KikiPaywall` components may render
  close affordances, but they should not decide whether closing means dismissing
  a settings sheet, completing onboarding, skipping a trial prompt, or opening a
  follow-up settings window.

## Host Flow Guidance

When a paywall appears inside onboarding, make every flow-out path explicit. A
common bug is to show onboarding based on `hasSeenOnboarding == false`, but only
mark it complete on purchase or trial start. If the user closes the app, restores
later, is already Pro, or closes the paywall without buying, onboarding can keep
appearing on every launch.

A common pattern is:

1. The onboarding controller owns `hasSeenOnboarding`.
2. Showing onboarding does not mark it complete.
3. Starting a trial, completing a purchase, restoring an entitlement, or tapping
   the onboarding paywall close button marks onboarding complete.
4. The host app decides what happens next, such as closing the onboarding window
   and opening Settings for follow-up configuration.

Before shipping, audit the onboarding flow for all exits: primary CTA, purchase
success, restore success, close button, app quit/relaunch, already-entitled
accounts, and error/cancel paths. Every intentional exit from onboarding should
either complete the flow or deliberately keep it pending.

Keep this orchestration in the app or starter template. Do not move entitlement
state, onboarding persistence, RevenueCat calls, or post-onboarding routing into
`KikiPaywall`.

## API Shape

- `KikiPaywallShell`: sheet-level chrome for paywall surfaces.
- `KikiPaywallHeader`: icon, title, and subtitle block.
- `KikiPaywallPlan`: display-only plan model.
- `KikiPaywallPlanCard`: selectable plan card.
- `KikiPaywallFeatureRow`: reusable benefit row.
- `KikiPaywallStatItem`: compact stat display.
- `KikiPaywallActionLabel`: primary/secondary action label with loading state.
- `KikiPaywallDefaults`: default sheet sizes and padding.

## TODO & Checklist

- Add a store protocol only after two apps need the same purchase flow shape.
- Keep trial, grandfathering, product ids, and access gating outside this module.
- Validate visual parity in Command Reopen after replacing local private components.
