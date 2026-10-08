# KikiReview

Review-request pacing, the system prompt, and an optional custom window.

## Request policy (recommended path)

`KikiReviewRequestPolicy` applies Apple's published rules; the host supplies
what counts as engagement, the moments that are natural stopping points, and
who may be asked.

- `KikiReviewRequestRules.recommended(minimumQualifyingEvents:)`: 14 days
  between requests, 3 per rolling year, once per `CFBundleVersion`.
- `evaluate(qualifyingEvents:isAudienceEligible:)` records nothing;
  `requestIfEligible(...)` records and then calls the host closure.
- Storage keys are host-supplied and store epoch seconds (`[Double]`), so an
  app can adopt existing request history without migration.
- `KikiSystemReviewRequest.request(in:)` uses `AppStore.requestReview(in:)`
  and falls back to the window-less StoreKit call only when no window exists.
- `KikiSystemReviewRequest.writeReviewURL(appStoreID:)` is for a persistent,
  user-chosen menu or Settings item — never for an automatic prompt.

Call sites follow Apple's StoreKit guidance: not at launch, not as the direct
result of a click, at the end of a completed sequence, and not for users whose
paid access has lapsed (`isAudienceEligible: false`).

## Custom window (host risk)

App Review Guideline 5.6.1 asks apps to use the provided API and states that
custom review prompts are disallowed. The window below remains for hosts that
explicitly accept that risk; it is not the default path.

A reusable custom review/feedback window. The app owns eligibility, frequency,
storage, copy, StoreKit calls and link actions; Kiki reports review/notNow/closed
without claiming a review was submitted.

- KikiReviewPromptConfiguration supplies window title, headline, message and
  button titles.
- KikiReviewPromptView is usable in a host-owned sheet.
- KikiReviewPromptController owns one window. Calling show while visible brings
  forward the current prompt; it does not replace the active callback or copy.
- The view keeps its 420-point width and grows from 310 to 560 points.
  Longer content scrolls. Action buttons stack when their labels do not fit.
  The controller tracks measured content size.
- Return invokes the primary action; Escape and the close control report closed.

## Localization

All review copy is caller-owned. The shared sheet's close accessibility label
uses the host main-bundle key `Close`.

## Validation

Hosting tests exercise the long-copy height ceiling. The Gallery exposes both
sheet and standalone-window routes. Product adoption of a custom review
introduction remains an explicit host decision.
