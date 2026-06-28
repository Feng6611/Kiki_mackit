import KikiSettings
import SwiftUI
import Testing

@MainActor
struct KikiAccessStatusPresentationTests {
    @Test("Presentation stores fields verbatim")
    func presentationStoresFields() {
        let presentation = KikiAccessStatusPresentation(
            tone: .trial,
            title: "Trial",
            subtitle: "3 days remaining",
            actionTitle: "Upgrade",
            isActionLoading: true
        )
        #expect(presentation.tone == .trial)
        #expect(presentation.title == "Trial")
        #expect(presentation.subtitle == "3 days remaining")
        #expect(presentation.actionTitle == "Upgrade")
        #expect(presentation.isActionLoading)
    }

    @Test("Access status card constructs with and without action")
    func cardIsConstructibleWithOrWithoutAction() {
        let withAction = KikiAccessStatusCard(
            presentation: KikiAccessStatusPresentation(
                tone: .active,
                title: "Pro",
                actionTitle: "Manage"
            ),
            action: {}
        )
        let withoutAction = KikiAccessStatusCard(
            presentation: KikiAccessStatusPresentation(tone: .neutral, title: "Not started")
        )
        _ = withAction.body
        _ = withoutAction.body
    }
}
