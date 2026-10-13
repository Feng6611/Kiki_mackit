import SwiftUI

/// About › Status as one settings row: the access state in a word, styled by
/// tone, so every app shows the same state the same way.
///
/// - Neutral (not paid, free tier, checking): `.secondary` text, no symbol.
/// - Trial: `clock` in the tint.
/// - Active and lifetime (any paid plan): `crown.fill` in the tint. The crown
///   means "Pro", whatever the plan.
/// - Expired: `exclamationmark.triangle` in orange.
///
/// With an action the row is a button and ends with a chevron; while
/// `isActionLoading` is set the row is inert (say "Checking…" in the title).
/// The row shows `presentation.title` only: subtitle and action title belong
/// to `KikiAccessStatusCard`.
public struct KikiAccessStatusRow: View {
    private let title: String
    private let presentation: KikiAccessStatusPresentation
    private let systemImage: String
    private let tint: Color
    private let action: (@MainActor () -> Void)?

    /// - Parameter title: the row's label, already localized (for example "Status").
    public init(
        title: String,
        presentation: KikiAccessStatusPresentation,
        systemImage: String = "info.circle",
        tint: Color = .accentColor,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.presentation = presentation
        self.systemImage = systemImage
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        if let action, !presentation.isActionLoading {
            Button(action: action) { row }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
        } else {
            row
        }
    }

    private var row: some View {
        KikiSettingsStatusRow(
            title: title,
            value: presentation.title,
            systemImage: systemImage,
            valueSystemImage: presentation.tone.rowSystemImage,
            tone: presentation.tone.settingsTone,
            tint: tint,
            trailingSystemImage: action != nil && !presentation.isActionLoading ? "chevron.right" : nil
        )
    }
}

public extension KikiAccessStatusTone {
    /// The symbol beside the value in `KikiAccessStatusRow`; `nil` for neutral.
    var rowSystemImage: String? {
        switch self {
        case .neutral: return nil
        case .trial: return "clock"
        case .active, .lifetime: return "crown.fill"
        case .expired: return "exclamationmark.triangle"
        }
    }
}
