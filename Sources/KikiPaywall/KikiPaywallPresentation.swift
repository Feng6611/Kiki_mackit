import AppKit
import Foundation
import SwiftUI

public enum KikiPaywallAccessState: Equatable, Sendable {
    case notStarted
    case trial
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

public struct KikiPaywallMessagePresentation: Equatable, Sendable {
    public let text: String
    public let tone: KikiPaywallMessageTone

    public init(text: String, tone: KikiPaywallMessageTone = .neutral) {
        self.text = text
        self.tone = tone
    }
}

public struct KikiPaywallLinkPresentation: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let url: URL

    public init(
        id: String,
        title: String,
        url: URL
    ) {
        self.id = id
        self.title = title
        self.url = url
    }
}

public struct KikiPaywallActionPresentation: Identifiable {
    public let id: UUID
    public let title: String
    public let isLoading: Bool
    private let isEnabled: @MainActor (_ selectedPlanID: String) -> Bool
    private let action: @MainActor (_ selectedPlanID: String) -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = UUID()
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = { _ in isEnabled }
        self.action = { _ in action() }
    }

    public init(
        id: UUID,
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = { _ in isEnabled }
        self.action = { _ in action() }
    }

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: @escaping @MainActor (_ selectedPlanID: String) -> Bool,
        action: @escaping @MainActor (_ selectedPlanID: String) -> Void
    ) {
        self.id = UUID()
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public init(
        id: UUID,
        title: String,
        isLoading: Bool = false,
        isEnabled: @escaping @MainActor (_ selectedPlanID: String) -> Bool,
        action: @escaping @MainActor (_ selectedPlanID: String) -> Void
    ) {
        self.id = id
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    @MainActor
    public func isEnabled(for selectedPlanID: String) -> Bool {
        isEnabled(selectedPlanID)
    }

    @MainActor
    public func perform(selectedPlanID: String) {
        guard isEnabled(for: selectedPlanID) else {
            return
        }
        action(selectedPlanID)
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
    public let footerLinks: [KikiPaywallLinkPresentation]
    public let message: KikiPaywallMessagePresentation?
    public let isInteractionDisabled: Bool
    public let primaryAction: KikiPaywallActionPresentation
    public let secondaryActions: [KikiPaywallActionPresentation]
    public let dismiss: (@MainActor () -> Void)?

    public init(
        accessState: KikiPaywallAccessState,
        headerTitle: String,
        headerSubtitle: String,
        plans: [KikiPaywallPlanPresentation],
        features: [String] = [],
        stats: [KikiPaywallStatConfig] = [],
        footnote: String? = nil,
        footerLinks: [KikiPaywallLinkPresentation] = [],
        message: KikiPaywallMessagePresentation? = nil,
        isInteractionDisabled: Bool = false,
        primaryAction: KikiPaywallActionPresentation,
        secondaryActions: [KikiPaywallActionPresentation] = [],
        dismiss: (@MainActor () -> Void)? = nil
    ) {
        self.accessState = accessState
        self.headerTitle = headerTitle
        self.headerSubtitle = headerSubtitle
        self.plans = plans
        self.features = features
        self.stats = stats
        self.footnote = footnote
        self.footerLinks = footerLinks
        self.message = message
        self.isInteractionDisabled = isInteractionDisabled
        self.primaryAction = primaryAction
        self.secondaryActions = secondaryActions
        self.dismiss = dismiss
    }
}

struct KikiPaywallPresentationFooter: View {
    let presentation: KikiPaywallPresentation

    var body: some View {
        VStack(spacing: 8) {
            if let message = presentation.message {
                KikiPaywallMessage(message.text, tone: message.tone)
            }

            if let footnote = presentation.footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if presentation.footerLinks.isEmpty == false {
                HStack(spacing: 10) {
                    ForEach(Array(presentation.footerLinks.enumerated()), id: \.element.id) { index, link in
                        if index > 0 {
                            KikiPaywallDotSeparator()
                        }
                        Button(link.title) {
                            NSWorkspace.shared.open(link.url)
                        }
                        .buttonStyle(.link)
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
