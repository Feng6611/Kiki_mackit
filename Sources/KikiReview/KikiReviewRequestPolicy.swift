import AppKit
import Foundation
import StoreKit

/// Pacing for App Store review requests, following Apple's published rules.
///
/// StoreKit already caps its own prompt at three displays a year and may show
/// nothing, so the app's job is choosing *when to ask*: only after real
/// engagement, not at launch, not as the direct result of a click, not twice
/// for the same version, and with a week or two between requests. This type
/// owns that bookkeeping. The host owns what counts as engagement, which
/// moments are natural stopping points, and who is eligible to be asked.
public struct KikiReviewRequestRules: Equatable, Sendable {
    /// Host-counted engagement events required before the first request.
    public var minimumQualifyingEvents: Int
    /// Minimum time between two requests from this app.
    public var minimumInterval: TimeInterval
    /// Requests per rolling 365 days. StoreKit enforces three on its side.
    public var maximumRequestsPerYear: Int
    /// Ask at most once for a given app version (`CFBundleVersion`).
    public var oncePerAppVersion: Bool

    public init(
        minimumQualifyingEvents: Int,
        minimumInterval: TimeInterval,
        maximumRequestsPerYear: Int,
        oncePerAppVersion: Bool
    ) {
        self.minimumQualifyingEvents = max(0, minimumQualifyingEvents)
        self.minimumInterval = max(0, minimumInterval)
        self.maximumRequestsPerYear = max(0, maximumRequestsPerYear)
        self.oncePerAppVersion = oncePerAppVersion
    }

    /// Apple's guidance with the host's engagement threshold: two weeks
    /// between requests, three a year, once per version.
    public static func recommended(minimumQualifyingEvents: Int) -> Self {
        Self(
            minimumQualifyingEvents: minimumQualifyingEvents,
            minimumInterval: 14 * 24 * 60 * 60,
            maximumRequestsPerYear: 3,
            oncePerAppVersion: true
        )
    }
}

public enum KikiReviewRequestSkipReason: Equatable, Sendable {
    /// The host says this user should not be asked now — for example, an
    /// expired trial whose feature has just stopped working.
    case audienceNotEligible
    case notEnoughEngagement
    case alreadyRequestedThisLaunch
    case alreadyRequestedThisVersion
    case tooSoon
    case yearlyLimitReached
}

public enum KikiReviewRequestDecision: Equatable, Sendable {
    case request
    case skip(KikiReviewRequestSkipReason)
}

public struct KikiReviewRequestStorageKeys: Equatable, Sendable {
    /// `[Double]` of request times as seconds since 1970.
    public let requestTimestamps: String
    public let lastRequestedVersion: String

    public init(requestTimestamps: String, lastRequestedVersion: String) {
        self.requestTimestamps = requestTimestamps
        self.lastRequestedVersion = lastRequestedVersion
    }

    public static func prefixed(_ prefix: String) -> Self {
        Self(
            requestTimestamps: "\(prefix).requestTimestamps",
            lastRequestedVersion: "\(prefix).lastRequestedVersion"
        )
    }
}

/// Decides whether a review request may be made now and records it when made.
///
/// Evaluating records nothing. `requestIfEligible` records and then calls the
/// host's `request` closure — normally `KikiSystemReviewRequest.request()`.
@MainActor
public final class KikiReviewRequestPolicy {
    public let rules: KikiReviewRequestRules
    private let defaults: UserDefaults
    private let keys: KikiReviewRequestStorageKeys
    private let appVersion: String
    private let now: () -> Date
    private var hasRequestedThisLaunch = false

    private static let rollingYear: TimeInterval = 365 * 24 * 60 * 60

    public init(
        rules: KikiReviewRequestRules,
        defaults: UserDefaults = .standard,
        keys: KikiReviewRequestStorageKeys,
        appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
        now: @escaping () -> Date = Date.init
    ) {
        self.rules = rules
        self.defaults = defaults
        self.keys = keys
        self.appVersion = appVersion
        self.now = now
    }

    public func evaluate(qualifyingEvents: Int, isAudienceEligible: Bool = true) -> KikiReviewRequestDecision {
        guard isAudienceEligible else { return .skip(.audienceNotEligible) }
        guard qualifyingEvents >= rules.minimumQualifyingEvents else { return .skip(.notEnoughEngagement) }
        guard !hasRequestedThisLaunch else { return .skip(.alreadyRequestedThisLaunch) }
        if rules.oncePerAppVersion,
           !appVersion.isEmpty,
           defaults.string(forKey: keys.lastRequestedVersion) == appVersion {
            return .skip(.alreadyRequestedThisVersion)
        }

        let current = now().timeIntervalSince1970
        let recent = requestTimestamps.filter { current - $0 < Self.rollingYear }
        if let last = recent.max(), current - last < rules.minimumInterval {
            return .skip(.tooSoon)
        }
        guard recent.count < rules.maximumRequestsPerYear else { return .skip(.yearlyLimitReached) }
        return .request
    }

    /// Records a request made now. Also prunes entries older than a year.
    public func recordRequest() {
        let current = now().timeIntervalSince1970
        let recent = requestTimestamps.filter { current - $0 < Self.rollingYear }
        defaults.set(recent + [current], forKey: keys.requestTimestamps)
        if !appVersion.isEmpty {
            defaults.set(appVersion, forKey: keys.lastRequestedVersion)
        }
        hasRequestedThisLaunch = true
    }

    @discardableResult
    public func requestIfEligible(
        qualifyingEvents: Int,
        isAudienceEligible: Bool = true,
        request: () -> Void
    ) -> Bool {
        guard evaluate(qualifyingEvents: qualifyingEvents, isAudienceEligible: isAudienceEligible) == .request else {
            return false
        }
        recordRequest()
        request()
        return true
    }

    private var requestTimestamps: [Double] {
        defaults.array(forKey: keys.requestTimestamps) as? [Double] ?? []
    }
}

/// The system review prompt and the persistent write-review link.
///
/// Apple's guideline 5.6.1 asks apps to use the provided API and disallows
/// custom review prompts; `KikiReviewPromptView` remains available only for
/// hosts that have explicitly accepted that review risk.
public enum KikiSystemReviewRequest {
    /// Asks StoreKit to show its rating prompt. StoreKit may show nothing.
    /// Never call this directly from a button: use `writeReviewURL` there.
    ///
    /// The prompt attaches to `viewController`, else to the key or first
    /// visible window. A menu bar app with no window open falls back to the
    /// window-less legacy call.
    @MainActor
    public static func request(in viewController: NSViewController? = nil) {
        let host = viewController
            ?? NSApp.keyWindow?.contentViewController
            ?? NSApp.windows.first(where: { $0.isVisible && $0.contentViewController != nil })?.contentViewController
        if let host {
            AppStore.requestReview(in: host)
        } else {
            LegacyReviewRequest().request()
        }
    }

    /// The App Store page that opens straight to "Write a Review". Suitable
    /// for a persistent menu or Settings item the user chooses deliberately.
    public static func writeReviewURL(appStoreID: String) -> URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}

/// Isolates the window-less StoreKit call, deprecated in macOS 15, to the
/// one case with no window to attach the modern prompt to.
private struct LegacyReviewRequest {
    @available(macOS, deprecated: 15.0)
    func requestDeprecated() {
        SKStoreReviewController.requestReview()
    }

    @MainActor
    func request() {
        (self as LegacyReviewRequesting).requestDeprecated()
    }
}

private protocol LegacyReviewRequesting {
    func requestDeprecated()
}

extension LegacyReviewRequest: LegacyReviewRequesting {}
