# KikiReview

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
