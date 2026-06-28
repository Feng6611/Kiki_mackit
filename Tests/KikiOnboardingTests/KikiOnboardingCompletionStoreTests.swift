import Foundation
import KikiOnboarding
import Testing

struct KikiOnboardingCompletionStoreTests {
    @Test("In-memory store reflects mark and reset")
    func inMemoryStoreRoundTrip() {
        let store = KikiOnboardingInMemoryCompletionStore()
        #expect(store.isCompleted(forKey: "demo") == false)

        store.markCompleted(forKey: "demo")
        #expect(store.isCompleted(forKey: "demo"))

        store.reset(forKey: "demo")
        #expect(store.isCompleted(forKey: "demo") == false)
    }

    @Test("In-memory store isolates keys")
    func inMemoryStoreIsolatesKeys() {
        let store = KikiOnboardingInMemoryCompletionStore()
        store.markCompleted(forKey: "alpha")
        #expect(store.isCompleted(forKey: "alpha"))
        #expect(store.isCompleted(forKey: "beta") == false)
    }

    @Test("UserDefaults store persists into the provided suite")
    func userDefaultsStorePersists() throws {
        let suiteName = "kiki.onboarding.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let store = KikiOnboardingUserDefaultsCompletionStore(defaults: defaults)
        let key = "onboarding.completed"

        #expect(store.isCompleted(forKey: key) == false)
        store.markCompleted(forKey: key)
        #expect(defaults.bool(forKey: key))
        #expect(store.isCompleted(forKey: key))

        store.reset(forKey: key)
        #expect(defaults.object(forKey: key) == nil)
        #expect(store.isCompleted(forKey: key) == false)
    }
}
