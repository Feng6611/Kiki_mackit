import AppKit
import SwiftUI
import Testing
@testable import KikiReview

@MainActor
struct KikiReviewLayoutTests {
    @Test("Long copy grows the review surface within its height ceiling")
    func longCopy() async {
        var measured = CGSize.zero
        let view = KikiReviewPromptView(
            configuration: .init(windowTitle: "Review", title: "A longer translated heading",
                message: String(repeating: "Long translated content with several words. ", count: 40),
                primaryActionTitle: "Eine Bewertung im App Store schreiben",
                secondaryActionTitle: "Vielleicht zu einem späteren Zeitpunkt"),
            onReview: {}, onNotNow: {}, onClose: {}
        ).reportingSize { measured = $0 }
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(x: 0, y: 0, width: 420, height: 560)
        for _ in 0..<30 {
            host.layoutSubtreeIfNeeded()
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(measured.width == 420)
        #expect(measured.height > KikiReviewPromptDefaults.height)
        #expect(measured.height <= KikiReviewPromptDefaults.maximumHeight)
    }
}
