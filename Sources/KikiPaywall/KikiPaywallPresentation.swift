import Foundation
import SwiftUI

public enum KikiPaywallAccessState: Equatable, Sendable {
    case notStarted
    case trial(daysRemaining: Int)
    case expired
    case entitled(planTitle: String)
}

public struct KikiPaywallPlanPresentation: Equatable, Identifiable, Sendable {
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

    public var paywallPlan: KikiPaywallPlan {
        KikiPaywallPlan(
            id: id,
            title: title,
            displayPrice: displayPrice,
            originalPrice: originalPrice,
            billingDetail: billingDetail,
            badge: badge,
            isAvailable: isAvailable
        )
    }
}

public struct KikiPaywallActions {
    public let purchase: @MainActor (_ planID: String) -> Void
    public let restore: @MainActor () -> Void
    public let startTrial: (@MainActor () -> Void)?
    public let dismiss: (@MainActor () -> Void)?

    public init(
        purchase: @escaping @MainActor (_ planID: String) -> Void,
        restore: @escaping @MainActor () -> Void,
        startTrial: (@MainActor () -> Void)? = nil,
        dismiss: (@MainActor () -> Void)? = nil
    ) {
        self.purchase = purchase
        self.restore = restore
        self.startTrial = startTrial
        self.dismiss = dismiss
    }
}

public struct KikiPaywallPresentation {
    public let accessState: KikiPaywallAccessState
    public let headerTitle: String
    public let headerSubtitle: String
    public let plans: [KikiPaywallPlanPresentation]
    public let features: [String]
    public let stats: [KikiPaywallStatConfig]
    public let footnote: String?
    public let isPurchaseInFlight: Bool
    public let isRestoreInFlight: Bool
    public let actions: KikiPaywallActions

    public init(
        accessState: KikiPaywallAccessState,
        headerTitle: String,
        headerSubtitle: String,
        plans: [KikiPaywallPlanPresentation],
        features: [String] = [],
        stats: [KikiPaywallStatConfig] = [],
        footnote: String? = nil,
        isPurchaseInFlight: Bool = false,
        isRestoreInFlight: Bool = false,
        actions: KikiPaywallActions
    ) {
        self.accessState = accessState
        self.headerTitle = headerTitle
        self.headerSubtitle = headerSubtitle
        self.plans = plans
        self.features = features
        self.stats = stats
        self.footnote = footnote
        self.isPurchaseInFlight = isPurchaseInFlight
        self.isRestoreInFlight = isRestoreInFlight
        self.actions = actions
    }

    public var primaryButtonTitle: String {
        switch accessState {
        case .entitled:
            return "Manage subscription"
        case .trial, .expired, .notStarted:
            return "Continue"
        }
    }

    public var canStartTrial: Bool {
        if case .notStarted = accessState {
            return actions.startTrial != nil
        }
        return false
    }
}
