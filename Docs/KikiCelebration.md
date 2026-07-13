# KikiCelebration Guidance

Celebration effects are an optional app-level capability. They should be used
for a meaningful completion or success moment—such as finishing onboarding,
starting a trial, or completing a purchase—not for ordinary state changes.

`Kiki_mackit` does not link a celebration package by default. Kiki stays UI-only
and keeps its dependency surface small; an app opts in when its product flow
needs the effect.

## Current App Dependency

Command Reopen currently uses
[`ConfettiSwiftUI`](https://github.com/simibac/ConfettiSwiftUI), pinned to `3.0.0`
in its Xcode project. It is a pure-SwiftUI package for macOS 11 and later, with
state-triggered confetti, built-in shapes, emoji, SF Symbols, text, colors,
repetition, and optional haptic feedback.

Add the package to the app target, then trigger it from a local integer state:

```swift
import ConfettiSwiftUI
import SwiftUI

struct SuccessButton: View {
    @State private var celebrationTrigger = 0

    var body: some View {
        Button("Done") {
            celebrationTrigger += 1
        }
        .confettiCannon(
            trigger: $celebrationTrigger,
            num: 32,
            confettis: [.shape(.circle), .shape(.roundedCross)],
            colors: [.accentColor, .orange, .yellow],
            confettiSize: 8,
            hapticFeedback: true
        )
    }
}
```

Keep the trigger local to the feature that owns the success event. Do not put
the package import or trigger state into `KikiOnboarding`, `KikiPaywall`, or
another shared workflow module.

## Choosing an Implementation

| Need | Recommendation | Trade-off |
| --- | --- | --- |
| Small confetti burst from a state change | `ConfettiSwiftUI` | Lowest integration cost; adds one optional dependency |
| A button-level spray, ping, shine, or haptic effect | [Pow](https://github.com/EmergeTools/Pow) | Broad SwiftUI effects, but it is not a full confetti system |
| Designer-authored, timeline-based animation | [Lottie](https://github.com/airbnb/lottie-ios) or [dotLottie](https://github.com/LottieFiles/dotlottie-ios) | More expressive and reusable assets; larger runtime and asset pipeline |
| One small branded success mark | Native SwiftUI (`Canvas`, `TimelineView`, or a local view animation) | No dependency; more implementation work and less reuse |

For the current onboarding and paywall flows, keep `ConfettiSwiftUI` as the
optional app dependency. Do not add Lottie or Pow until a product needs their
specific capabilities. If at least three apps need the same celebration API,
extract a thin Kiki-facing abstraction while keeping the third-party package
behind that boundary.

## Accessibility and Product Rules

- Respect Reduce Motion; provide a static success mark when motion is reduced.
- Never make confetti the only indication of success; keep text and state clear.
- Avoid firing on every view appearance. Trigger only after the user completes
  the intended action.
- Keep haptic feedback optional because it is not equally appropriate for all
  products and contexts.
