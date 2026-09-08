import KikiReview
import SwiftUI
import Testing

struct KikiReviewTests {
    @Test("Review prompt configuration keeps caller-owned copy")
    func configurationKeepsCallerOwnedCopy() {
        let configuration = KikiReviewPromptConfiguration(
            windowTitle: "Feedback",
            title: "Enjoying Example App?",
            message: "A short review helps other people find it.",
            primaryActionTitle: "Review on App Store",
            secondaryActionTitle: "Not Now"
        )

        #expect(configuration.windowTitle == "Feedback")
        #expect(configuration.title == "Enjoying Example App?")
        #expect(configuration.message == "A short review helps other people find it.")
        #expect(configuration.primaryActionTitle == "Review on App Store")
        #expect(configuration.secondaryActionTitle == "Not Now")
    }

    @MainActor
    @Test("Review prompt view and single-window controller are constructible")
    func viewAndControllerAreConstructible() {
        let configuration = KikiReviewPromptConfiguration(
            windowTitle: "Feedback",
            title: "Enjoying Example App?",
            message: "A short review helps other people find it.",
            primaryActionTitle: "Review on App Store",
            secondaryActionTitle: "Not Now"
        )
        let view = KikiReviewPromptView(
            configuration: configuration,
            onReview: {},
            onNotNow: {},
            onClose: {}
        )
        let controller = KikiReviewPromptController()

        _ = view
        #expect(!controller.isVisible)
    }
}
