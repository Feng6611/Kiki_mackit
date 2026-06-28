import SwiftUI

public struct KikiOnboardingConfiguration {
    public let appName: String
    public let tint: Color
    public let steps: [KikiOnboardingStep]
    public let completionKey: String
    public let windowAutosaveName: String
    public let windowTitle: String

    public init(
        appName: String,
        steps: [KikiOnboardingStep],
        completionKey: String,
        tint: Color = .accentColor,
        windowAutosaveName: String = "KikiOnboarding.Window",
        windowTitle: String = "Welcome"
    ) {
        self.appName = appName
        self.tint = tint
        self.steps = steps
        self.completionKey = completionKey
        self.windowAutosaveName = windowAutosaveName
        self.windowTitle = windowTitle
    }
}
