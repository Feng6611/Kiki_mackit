import Foundation

public struct KikiOnboardingAction {
    public let title: String
    public let isEnabled: Bool
    public let action: @MainActor () -> Void

    public init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
}
