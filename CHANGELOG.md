# Changelog

## 0.4.0 - 2026-05-16

### Added

- Added the `KikiDesign` product for adaptive glass and reusable material surface primitives.
- Added the `KikiWindow` product for SwiftUI-hosted single-window presentation and transparent AppKit window background helpers.
- Expanded `KikiMenuBar` with native menu item declarations, standard shortcuts, status/link/toggle items, settings/about/quit helpers, and SwiftUI popover support.
- Expanded `KikiPaywall` with reusable paywall display models, shell layout, plan cards, feature rows, action labels, and optional standalone window presentation.
- Added an internal `KikiCore` target for package-shared AppKit helpers.

### Changed

- Split `KikiSettings` into focused source files while preserving the public API surface.
- Updated Settings, MenuBar, Paywall, Design, and Window documentation to reflect the current module boundaries.
- Routed repeated URL-opening behavior through shared package-internal helpers.
- Updated app activation helpers to use the macOS 14+ activation API when available.

### Fixed

- Documented the Settings opener fallback selector used after the explicit main-menu Settings item search fails.
- Improved Settings opener behavior coverage for disabled menu items.

### Tests

- Added focused tests for menu toggle state mapping, Settings opener menu traversal, KikiDesign construction, KikiWindow construction, and expanded paywall display components.
