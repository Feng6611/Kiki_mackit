# KikiMenuBar

## Feature List

- Owns `NSStatusItem` lifecycle for menu bar apps.
- Supports system symbol image, tooltip, autosave name, and dynamic menu generation.
- Supports action items, toggle items, link items, status items, standard settings/about/quit items, separators, disabled state, and keyboard shortcuts.
- Supports SwiftUI popover menu bar apps through `KikiMenuBarPopoverController`.

## Technical Decisions

- AppKit-first because menu bar behavior is based on `NSStatusItem` and `NSMenu`.
- The app supplies menu items or popover content through closures so product-specific state stays outside the package.
- Menu item actions are closures, not selectors, to keep app adapters small.
- `KikiMenuBarPopoverController` owns only the AppKit bridge: status item, popover, hosting controller, sizing, and show/close behavior. Product popover UI stays in app code.
- Popovers are not standalone windows in Kiki's API model. Use `KikiWindow`
  only for independent utility/help/onboarding/paywall windows.
- Popover visuals can reuse `KikiDesign` surfaces while lifecycle stays here.

## TODO & Checklist

- Add submenu support when the first app needs it.
- Keep product-specific menu labels and upgrade logic in app code.
- Keep SwiftUI popover rows, lists, and business actions in app code until several apps repeat the same UI.
