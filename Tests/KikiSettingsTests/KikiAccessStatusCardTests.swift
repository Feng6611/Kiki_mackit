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
        let rowWithTrailingStatusIcon = KikiSettingsStatusRow(
            title: "Status",
            value: "Lifetime",
            systemImage: "info.circle",
            valueSystemImage: "crown.fill",
            tone: .accent,
            showsBadge: false
        )
        _ = withAction.body
        _ = withoutAction.body
        _ = rowWithTrailingStatusIcon.body
    }

    @Test("Lifetime status uses a crown and brand tone")
    func lifetimeUsesBrandPresentation() {
        #expect(KikiAccessStatusTone.lifetime.systemImage == "crown.fill")
        #expect(KikiAccessStatusTone.lifetime.settingsTone == .accent)
    }

    @Test("Neutral status is distinct from an expired warning")
    func accessStatusUsesStableTwoTonePresentation() {
        #expect(KikiAccessStatusTone.neutral.settingsTone == .neutral)
        #expect(KikiAccessStatusTone.expired.settingsTone == .warning)
        #expect(KikiAccessStatusTone.trial.settingsTone == .accent)
        #expect(KikiAccessStatusTone.active.settingsTone == .accent)
        #expect(KikiAccessStatusTone.lifetime.settingsTone == .accent)
    }
}

@MainActor
struct KikiAccessStatusRowTests {
    @Test("The row marks every paid plan with the crown and keeps neutral plain")
    func rowSymbols() {
        #expect(KikiAccessStatusTone.neutral.rowSystemImage == nil)
        #expect(KikiAccessStatusTone.trial.rowSystemImage == "clock")
        #expect(KikiAccessStatusTone.active.rowSystemImage == "crown.fill")
        #expect(KikiAccessStatusTone.lifetime.rowSystemImage == "crown.fill")
        #expect(KikiAccessStatusTone.expired.rowSystemImage == "exclamationmark.triangle")
    }

    @Test("Access status row constructs with and without action")
    func rowIsConstructible() {
        let free = KikiAccessStatusRow(
            title: "Status",
            presentation: KikiAccessStatusPresentation(tone: .neutral, title: "Free"),
            action: {}
        )
        let owner = KikiAccessStatusRow(
            title: "Status",
            presentation: KikiAccessStatusPresentation(tone: .lifetime, title: "Lifetime"),
            tint: .purple
        )
        _ = free.body
        _ = owner.body
    }
}
