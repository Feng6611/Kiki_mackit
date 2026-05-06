# KikiMenuBar

## Feature List

- Owns `NSStatusItem` lifecycle for menu bar apps.
- Supports system symbol image, tooltip, autosave name, and dynamic menu generation.
- Supports action items, toggle items, separators, disabled state, and keyboard shortcuts.

## Technical Decisions

- AppKit-first because menu bar behavior is based on `NSStatusItem` and `NSMenu`.
- The app supplies menu items through a closure so product-specific state stays outside the package.
- Menu item actions are closures, not selectors, to keep app adapters small.

## TODO & Checklist

- Add submenu support when the first app needs it.
- Keep product-specific menu labels and upgrade logic in app code.
- Before public release, add an example menu bar app using only this module.
