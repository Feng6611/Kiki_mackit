import AppKit
import SwiftUI

public enum KikiPaywallDefaults {
    public static let sheetWidth: CGFloat = 500
    public static let sheetHeight: CGFloat = 520
    public static let onboardingSheetWidth: CGFloat = 520
    public static let onboardingSheetHeight: CGFloat = 520
    public static let windowWidth: CGFloat = 520
    public static let windowHeight: CGFloat = 620
    public static let sheetPadding: CGFloat = 28

    /// Floor for a sheet that measures itself. Below this a sheet with only a
    /// header and one button stops reading as a sheet.
    public static let minimumSheetHeight: CGFloat = 380

    /// Ceiling for a compact sheet. Past this the content scrolls rather than
    /// growing a settings sheet taller than a small display's free space.
    public static let maximumSheetHeight: CGFloat = 720

    @available(*, deprecated, message: "Sheets measure their content; slack constants are no longer used.")
    public static let baseContentSlack: CGFloat = 56

    @available(*, deprecated, message: "Sheets measure their content; row-height constants are no longer used.")
    public static let minimumActionsGap: CGFloat = 20

    @available(*, deprecated, message: "Sheets measure their content; row-height constants are no longer used.")
    public static let statsRowHeight: CGFloat = 76

    @available(*, deprecated, message: "Sheets measure their content; row-height constants are no longer used.")
    public static let planRowHeight: CGFloat = 112

    @available(*, deprecated, message: "Sheets measure their content; row-height constants are no longer used.")
    public static let secondaryActionRowHeight: CGFloat = 44
}

public enum KikiPaywallSheetSize: Sendable {
    case compact
    case onboarding

    public var width: CGFloat {
        switch self {
        case .compact: return KikiPaywallDefaults.sheetWidth
        case .onboarding: return KikiPaywallDefaults.onboardingSheetWidth
        }
    }

    /// The height a sheet opens at, before its content reports its own.
    public var height: CGFloat {
        switch self {
        case .compact: return KikiPaywallDefaults.sheetHeight
        case .onboarding: return KikiPaywallDefaults.onboardingSheetHeight
        }
    }

    public var minimumHeight: CGFloat {
        KikiPaywallDefaults.minimumSheetHeight
    }

    /// How tall the sheet may grow before its content scrolls.
    ///
    /// An onboarding paywall is hosted inside the welcome window and cannot
    /// exceed it, so it is capped at its own height. A settings sheet has the
    /// screen to itself and may grow.
    public var maximumHeight: CGFloat {
        switch self {
        case .compact: return KikiPaywallDefaults.maximumSheetHeight
        case .onboarding: return KikiPaywallDefaults.onboardingSheetHeight
        }
    }
}

public struct KikiPaywallPlan: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let displayPrice: String
    public let originalPrice: String?
    public let billingDetail: String
    public let badge: String?
    public let isAvailable: Bool

    public init(
        id: String,
        title: String,
        displayPrice: String,
        originalPrice: String? = nil,
        billingDetail: String,
        badge: String? = nil,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.displayPrice = displayPrice
        self.originalPrice = originalPrice
        self.billingDetail = billingDetail
        self.badge = badge
        self.isAvailable = isAvailable
    }
}

public struct KikiPaywallHeaderConfig {
    public let title: String
    public let subtitle: String
    public let icon: NSImage?

    public init(
        title: String,
        subtitle: String,
        icon: NSImage? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

/// Two configs with the same `value` and `label` derive the same `id` and
/// are treated as one element by `ForEach`. Pass an explicit `id` when the
/// same stat must appear more than once.
public struct KikiPaywallStatConfig: Identifiable, Equatable {
    public let id: String
    public let value: String
    public let label: String

    public init(id: String? = nil, value: String, label: String) {
        self.id = id ?? "\(value)\u{1F}\(label)"
        self.value = value
        self.label = label
    }
}

/// Visual weight for a paywall action.
///
/// - `bordered`: full-width bordered button rendered in the actions area
///   under the primary CTA (current default).
/// - `footerLink`: subtle text-only link rendered in a dot-separated row
///   inside the footer slot. Use for restore, retry, or "manage subscription"
///   style actions that should not compete with the primary purchase CTA.
public enum KikiPaywallActionStyle: Sendable {
    case bordered
    case footerLink
}

public struct KikiPaywallActionConfig: Identifiable {
    public let id: UUID
    public let title: String
    public let isLoading: Bool
    public let isEnabled: Bool
    public let style: KikiPaywallActionStyle
    public let action: @MainActor () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: KikiPaywallActionStyle = .bordered,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = UUID()
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }

    public init(
        id: UUID,
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: KikiPaywallActionStyle = .bordered,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }
}
