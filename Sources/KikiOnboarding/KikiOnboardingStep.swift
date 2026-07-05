import Foundation
import SwiftUI

public struct KikiOnboardingWelcomeContent: Equatable {
    public let title: String
    public let body: String?
    public let iconSystemName: String
    public let rows: [KikiOnboardingRow]
    public let continueTitle: String
    public let skipTitle: String?

    public init(
        title: String,
        body: String? = nil,
        iconSystemName: String = "sparkles",
        rows: [KikiOnboardingRow] = [],
        continueTitle: String = "Continue",
        skipTitle: String? = nil
    ) {
        self.title = title
        self.body = body
        self.iconSystemName = iconSystemName
        self.rows = rows
        self.continueTitle = continueTitle
        self.skipTitle = skipTitle
    }
}

public struct KikiOnboardingFeatureContent: Equatable {
    public let title: String
    public let body: String?
    public let iconSystemName: String
    public let rows: [KikiOnboardingRow]
    public let continueTitle: String
    public let backTitle: String?

    public init(
        title: String,
        body: String? = nil,
        iconSystemName: String = "checkmark.seal",
        rows: [KikiOnboardingRow],
        continueTitle: String = "Continue",
        backTitle: String? = "Back"
    ) {
        self.title = title
        self.body = body
        self.iconSystemName = iconSystemName
        self.rows = rows
        self.continueTitle = continueTitle
        self.backTitle = backTitle
    }
}

public struct KikiOnboardingPermissionContent {
    public let title: String
    public let body: String?
    public let iconSystemName: String
    public let permissionRow: KikiOnboardingPermissionRow
    public let continueTitle: String
    public let backTitle: String?

    public init(
        title: String,
        body: String? = nil,
        iconSystemName: String = "lock.shield",
        permissionRow: KikiOnboardingPermissionRow,
        continueTitle: String = "Continue",
        backTitle: String? = "Back"
    ) {
        self.title = title
        self.body = body
        self.iconSystemName = iconSystemName
        self.permissionRow = permissionRow
        self.continueTitle = continueTitle
        self.backTitle = backTitle
    }
}

public struct KikiOnboardingSuccessContent: Equatable {
    public let title: String
    public let body: String?
    public let iconSystemName: String
    public let finishTitle: String

    public init(
        title: String,
        body: String? = nil,
        iconSystemName: String = "checkmark.circle.fill",
        finishTitle: String = "Done"
    ) {
        self.title = title
        self.body = body
        self.iconSystemName = iconSystemName
        self.finishTitle = finishTitle
    }
}

public struct KikiOnboardingNavigation {
    public let advance: @MainActor () -> Void
    public let back: @MainActor () -> Void
    public let skip: @MainActor () -> Void
    public let finish: @MainActor () -> Void

    public init(
        advance: @escaping @MainActor () -> Void,
        back: @escaping @MainActor () -> Void,
        skip: @escaping @MainActor () -> Void,
        finish: @escaping @MainActor () -> Void
    ) {
        self.advance = advance
        self.back = back
        self.skip = skip
        self.finish = finish
    }
}

public enum KikiOnboardingStep {
    case welcome(KikiOnboardingWelcomeContent)
    case features(KikiOnboardingFeatureContent)
    case permission(KikiOnboardingPermissionContent)
    case success(KikiOnboardingSuccessContent)
    case paywallHandoff
    case custom(id: String, view: @MainActor (KikiOnboardingNavigation) -> AnyView)

    public var id: String {
        switch self {
        case .welcome: return "welcome"
        case .features: return "features"
        case .permission: return "permission"
        case .success: return "success"
        case .paywallHandoff: return "paywallHandoff"
        case .custom(let id, _): return "custom.\(id)"
        }
    }
}
