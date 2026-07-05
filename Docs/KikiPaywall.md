# KikiPaywall

## Feature List

- Lightweight paywall plan model.
- Reusable paywall sheet/content shell and header.
- Optional standalone paywall window controller.
- Reusable plan card, feature row, stat item, and action label views.
- Loading, disabled, selected, and unavailable visual states.

## Technical Decisions

- SwiftUI-first because this module is presentation-focused.
- No RevenueCat dependency; purchasing and entitlement policy belong to the app
  or the separate `KikiCommerceKit` package.
- `KikiPaywallShell` extracts a stable small-app paywall sheet structure:
  scrollable header/content, fixed action/footer area, optional close button,
  default sheet sizes, and subtle native material background.
- `KikiPaywallWindowController` is only a presentation adapter. It uses
  `KikiWindow` to host app-provided paywall content in a standalone `NSWindow`
  when a sheet is not the right product surface.
- The shell is not a full purchase flow. The host app or `KikiCommerceKit` supplies
  content, action buttons, footer links, loading state, close behavior, and all
  side effects.
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

Keep this orchestration in the app, starter template, or `KikiCommerceKit`. Do not
move entitlement state, onboarding persistence, RevenueCat calls, or
post-onboarding routing into `KikiPaywall`.

## API Shape

- `KikiPaywallShell`: sheet/content-level chrome for paywall surfaces.
- `KikiPaywallWindowController`: optional standalone window presenter.
- `KikiPaywallHeader`: icon, title, and subtitle block.
- `KikiPaywallPlan`: display-only plan model.
- `KikiPaywallPlanCard`: selectable plan card.
- `KikiPaywallFeatureRow`: reusable benefit row.
- `KikiPaywallStatItem`: compact stat display.
- `KikiPaywallActionLabel`: primary/secondary action label with loading state.
- `KikiPaywallDefaults`: default sheet/window sizes and padding.
- `KikiPaywallSheet`: one-call preset that arranges header, stats, features,
  plan cards, primary CTA, and footer for the most common host shape.

## High-Level Feature: `KikiPaywallPresentation`

`KikiPaywallSheet` is an atom layer that takes raw closures and stats. Most
apps go through one more level of indirection: a Commerce-agnostic
presentation that captures *what the user should see right now* without
embedding RevenueCat types or trial math.

- `KikiPaywallAccessState`: `.notStarted | .trial | .expired | .entitled`.
  Host code (or `KikiCommerceKit`) derives this from its own commerce stack.
- `KikiPaywallPlanPresentation`: pure display fields for a plan; maps to the
  `KikiPaywallPlan` atom via `paywallPlan`.
- `KikiPaywallActionPresentation`: caller-owned title, loading state,
  plan-aware enabled predicate, and action. There is no purchase-specific action
  enum in Base Kit.
- `KikiPaywallPresentation`: full snapshot — access state, header copy,
  plans, features, stats, typed feedback, footnote, footer links, interaction
  state, one primary action, ordered secondary actions, and optional dismiss.

Two preset views consume this presentation:

- `KikiCompactPaywall`: settings-sheet-sized preset.
- `KikiOnboardingPaywall`: larger onboarding-paywall preset.

Neither view touches Commerce or decides which action is purchase, restore,
trial, or dismiss. The host (or `KikiCommerceKit` adapter) constructs the
presentation and feeds it in.

```swift
let presentation = KikiPaywallPresentation(
    accessState: .notStarted,
    headerTitle: "My App Pro",
    headerSubtitle: "Unlock all features",
    plans: planPresentations,
    primaryAction: KikiPaywallActionPresentation(
        title: "Unlock",
        isEnabled: { planID in availablePlanIDs.contains(planID) },
        action: { planID in purchase(planID) }
    ),
    secondaryActions: [
        KikiPaywallActionPresentation(title: "Restore", action: restore)
    ]
)
KikiCompactPaywall(presentation: presentation, selectedPlanID: $planID)
```

## Default Shape With KikiPaywallSheet

The shell + atoms approach stays available, but most apps only need the
preset. `KikiPaywallSheet` accepts data and closures:

```swift
KikiPaywallSheet(
    header: .init(title: "My App", subtitle: "Unlock the full app"),
    stats: [.init(value: "3", label: "Reusable kits")],
    features: ["Menu bar shell", "Settings shell", "Paywall preset"],
    plans: planProducts,
    selectedPlanID: $selectedPlanID,
    primary: .init(
        title: isPro ? "Already Pro" : "Mock Purchase",
        isLoading: isPurchasing,
        isEnabled: !isPro,
        action: purchaseSelectedPlan
    ),
    secondary: .init(
        title: "Restore Purchase",
        isLoading: false,
        isEnabled: !isPro,
        action: restore
    )
)
```

The sheet builds on top of `KikiPaywallShell`, so hosts that need custom
sections can drop down to the shell and atoms without losing visual parity.

## TODO & Checklist

- Put shared RevenueCat, trial, restore, and entitlement state in
  `KikiCommerceKit`, not `KikiPaywall`.
- Keep grandfathering, product ids, and product-specific access gating outside
  this module.
- Validate visual parity in host apps after replacing local private components.
