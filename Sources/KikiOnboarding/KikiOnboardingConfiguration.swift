import SwiftUI

public enum KikiOnboardingDefaults {
    public static let windowSize = CGSize(width: 680, height: 680)
}

public enum KikiOnboardingCloseDisposition: Equatable, Sendable {
    /// Closing the window leaves onboarding pending for a future launch.
    case keepPending
    /// Closing the window commits completion and invokes `onFinished`.
    case complete
}

public struct KikiOnboardingConfiguration {
    public let appName: String
    public let tint: Color
    public let steps: [KikiOnboardingStep]
    public let canSkip: Bool
    public let completionKey: String
    public let windowAutosaveName: String
    public let windowTitle: String
    public let windowSize: CGSize
    public let minimumWindowSize: CGSize?
    public let closeDisposition: KikiOnboardingCloseDisposition

    public init(
        appName: String,
        steps: [KikiOnboardingStep],
        completionKey: String,
        canSkip: Bool = false,
        tint: Color = .accentColor,
        windowAutosaveName: String = "KikiOnboarding.Window",
        windowTitle: String = "Welcome",
        windowSize: CGSize = KikiOnboardingDefaults.windowSize,
        minimumWindowSize: CGSize? = KikiOnboardingDefaults.windowSize,
        closeDisposition: KikiOnboardingCloseDisposition = .keepPending
    ) {
        self.appName = appName
        self.tint = tint
        self.steps = steps
        self.canSkip = canSkip
        self.completionKey = completionKey
        self.windowAutosaveName = windowAutosaveName
        self.windowTitle = windowTitle
        self.windowSize = windowSize
        self.minimumWindowSize = minimumWindowSize
        self.closeDisposition = closeDisposition
    }
}
