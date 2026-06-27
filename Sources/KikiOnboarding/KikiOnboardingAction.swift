import Foundation

public struct KikiOnboardingAction {
    public let title: String
    public let action: @MainActor () -> Void

    public init(
        title: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.action = action
    }
}
