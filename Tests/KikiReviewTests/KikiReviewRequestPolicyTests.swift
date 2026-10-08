import Foundation
import Testing
@testable import KikiReview

@MainActor
struct KikiReviewRequestPolicyTests {
    private let day: TimeInterval = 24 * 60 * 60

    @Test("Engagement and audience gate the first request")
    func engagementAndAudience() {
        let (policy, _, cleanup) = makePolicy(version: "10", now: { Date(timeIntervalSince1970: 1_700_000_000) })
        defer { cleanup() }

        #expect(policy.evaluate(qualifyingEvents: 4) == .skip(.notEnoughEngagement))
        #expect(policy.evaluate(qualifyingEvents: 5, isAudienceEligible: false) == .skip(.audienceNotEligible))
        #expect(policy.evaluate(qualifyingEvents: 5) == .request)
    }

    @Test("One request per launch and per app version")
    func perLaunchAndVersion() {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let (policy, defaults, cleanup) = makePolicy(version: "10", now: { now })
        defer { cleanup() }

        var requested = 0
        #expect(policy.requestIfEligible(qualifyingEvents: 5) { requested += 1 })
        #expect(policy.evaluate(qualifyingEvents: 50) == .skip(.alreadyRequestedThisLaunch))

        now = now.addingTimeInterval(30 * day)
        let nextLaunch = KikiReviewRequestPolicy(
            rules: .recommended(minimumQualifyingEvents: 5), defaults: defaults,
            keys: .prefixed("test.review"), appVersion: "10", now: { now })
        #expect(nextLaunch.evaluate(qualifyingEvents: 50) == .skip(.alreadyRequestedThisVersion))

        let nextVersion = KikiReviewRequestPolicy(
            rules: .recommended(minimumQualifyingEvents: 5), defaults: defaults,
            keys: .prefixed("test.review"), appVersion: "11", now: { now })
        #expect(nextVersion.evaluate(qualifyingEvents: 50) == .request)
        #expect(requested == 1)
    }

    @Test("Requests keep a minimum interval and a yearly cap")
    func intervalAndYearlyCap() {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let rules = KikiReviewRequestRules(minimumQualifyingEvents: 0, minimumInterval: 14 * day,
                                           maximumRequestsPerYear: 3, oncePerAppVersion: false)
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        func launch() -> KikiReviewRequestPolicy {
            KikiReviewRequestPolicy(rules: rules, defaults: defaults, keys: .prefixed("t"), appVersion: "1", now: { now })
        }

        #expect(launch().requestIfEligible(qualifyingEvents: 0) {})
        now = now.addingTimeInterval(7 * day)
        #expect(launch().evaluate(qualifyingEvents: 0) == .skip(.tooSoon))
        now = now.addingTimeInterval(7 * day)
        #expect(launch().requestIfEligible(qualifyingEvents: 0) {})
        now = now.addingTimeInterval(14 * day)
        #expect(launch().requestIfEligible(qualifyingEvents: 0) {})
        now = now.addingTimeInterval(14 * day)
        #expect(launch().evaluate(qualifyingEvents: 0) == .skip(.yearlyLimitReached))
        now = now.addingTimeInterval(365 * day)
        #expect(launch().evaluate(qualifyingEvents: 0) == .request)
    }

    @Test("Existing epoch-second history is honoured")
    func adoptsExistingHistory() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let keys = KikiReviewRequestStorageKeys(requestTimestamps: "legacyTimestamps", lastRequestedVersion: "legacyVersion")
        defaults.set([now.timeIntervalSince1970 - day], forKey: "legacyTimestamps")

        let policy = KikiReviewRequestPolicy(rules: .recommended(minimumQualifyingEvents: 0), defaults: defaults,
                                             keys: keys, appVersion: "1", now: { now })
        #expect(policy.evaluate(qualifyingEvents: 0) == .skip(.tooSoon))
    }

    @Test("Write-review link opens the review composer")
    func writeReviewURL() {
        #expect(KikiSystemReviewRequest.writeReviewURL(appStoreID: "123")?.absoluteString
            == "https://apps.apple.com/app/id123?action=write-review")
    }

    private func makePolicy(version: String, now: @escaping () -> Date)
        -> (KikiReviewRequestPolicy, UserDefaults, () -> Void) {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        let policy = KikiReviewRequestPolicy(rules: .recommended(minimumQualifyingEvents: 5), defaults: defaults,
                                             keys: .prefixed("test.review"), appVersion: version, now: now)
        return (policy, defaults, { defaults.removePersistentDomain(forName: suiteName) })
    }
}
