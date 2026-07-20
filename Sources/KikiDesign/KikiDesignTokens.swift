import SwiftUI

/// Shared visual tokens for custom chrome that system controls don't cover
/// (cards, badges, hero surfaces). Semantic fonts and colors remain the
/// default; these tokens only govern repeated opacity and radius values so
/// features don't drift into per-component magic numbers.
public enum KikiDesignTokens {
    /// Fill opacities form a four-level hierarchy, weakest to strongest:
    /// subtle (0.06) < medium (0.08) < badge (0.12) < strong (0.14).
    /// Pick the weakest level that still reads against the surface.
    public enum Opacity {
        /// Level 1: barely-there tint wash. Anchor: selected plan-card fill.
        public static let subtleFill: Double = 0.06
        /// Level 2: raised-panel tint. Anchor: stats panel, scaffold gradient.
        public static let mediumFill: Double = 0.08
        /// Level 3: status capsule. Anchor: settings status badge.
        public static let badgeFill: Double = 0.12
        /// Level 4: icon well. Anchor: icon badge, hero background.
        public static let strongFill: Double = 0.14
        /// Dimmed content for unavailable custom controls. Plain-style
        /// buttons don't dim on their own, so custom cards apply this
        /// explicitly.
        public static let disabledContent: Double = 0.45
        /// Opacity of a selected card's tint border.
        public static let selectedStrokeOpacity: Double = 0.5
    }

    /// Corner radii from small cards to large hero surfaces.
    public enum CornerRadius {
        /// Compact custom cards. Anchor: plan card, plan row.
        public static let card: CGFloat = 10
        /// Raised panels. Anchor: stats panel, permission row.
        public static let panel: CGFloat = 12
        /// Elevated card modifier. Anchor: `kikiPaywallCard`.
        public static let elevatedCard: CGFloat = 14
        /// Large icon wells. Anchor: paywall header icon, symbol hero.
        public static let iconLarge: CGFloat = 18
        /// App-icon hero. Anchor: onboarding hero.
        public static let heroIcon: CGFloat = 20
    }

    public enum Separator {
        /// Muted card border over `NSColor.separatorColor`.
        public static let mutedOpacity: Double = 0.4
    }
}
