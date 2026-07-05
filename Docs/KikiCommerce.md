# KikiCommerce (moved)

The `KikiCommerce` product was removed from Kiki_mackit before 0.7.0.
Paid-access workflow now lives in the separate optional `KikiCommerceKit`
package:

- `KikiCommerceCore`: provider-neutral entitlement, trial, plan, and access
  workflow.
- `KikiRevenueCat`: RevenueCat transport and verified legacy entitlement
  mapping.
- `KikiCommercePresentation`: adapter from access workflow to the display-only
  `KikiPaywallPresentation` API in this package.

Kiki_mackit remains commerce-free. Keep this file only as a migration pointer;
the authoritative commerce documentation is `KikiCommerceKit/README.md` and
the workspace `BUILD_SYSTEM.md`.
