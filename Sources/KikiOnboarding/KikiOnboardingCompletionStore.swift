import Foundation

public protocol KikiOnboardingCompletionStore: AnyObject {
    func isCompleted(forKey key: String) -> Bool
    func markCompleted(forKey key: String)
    func reset(forKey key: String)
}

public final class KikiOnboardingUserDefaultsCompletionStore: KikiOnboardingCompletionStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isCompleted(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    public func markCompleted(forKey key: String) {
        defaults.set(true, forKey: key)
    }

    public func reset(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

public final class KikiOnboardingInMemoryCompletionStore: KikiOnboardingCompletionStore {
    private var state: [String: Bool] = [:]

    public init() {}

    public func isCompleted(forKey key: String) -> Bool {
        state[key] ?? false
    }

    public func markCompleted(forKey key: String) {
        state[key] = true
    }

    public func reset(forKey key: String) {
        state.removeValue(forKey: key)
    }
}
