import SwiftUI

public enum KikiAccessStatusTone: Equatable, Sendable {
    case neutral
    case trial
    case active
    case expired
}

public struct KikiAccessStatusPresentation: Equatable, Sendable {
    public let tone: KikiAccessStatusTone
    public let title: String
    public let subtitle: String?
    public let actionTitle: String?
    public let isActionLoading: Bool

    public init(
        tone: KikiAccessStatusTone,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        isActionLoading: Bool = false
    ) {
        self.tone = tone
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.isActionLoading = isActionLoading
    }
}

public struct KikiAccessStatusCard: View {
    private let presentation: KikiAccessStatusPresentation
    private let action: (@MainActor () -> Void)?

    public init(
        presentation: KikiAccessStatusPresentation,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.presentation = presentation
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .center, spacing: KikiSettingsSpacing.sm) {
            badge

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.system(size: 14, weight: .semibold))
                if let subtitle = presentation.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if let actionTitle = presentation.actionTitle, let action {
                Button {
                    action()
                } label: {
                    if presentation.isActionLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(actionTitle)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(presentation.isActionLoading)
            }
        }
    }

    private var badge: some View {
        Image(systemName: toneSymbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(toneColor)
            )
    }

    private var toneSymbol: String {
        switch presentation.tone {
        case .neutral: return "info.circle"
        case .trial: return "clock"
        case .active: return "checkmark.seal"
        case .expired: return "exclamationmark.triangle"
        }
    }

    private var toneColor: Color {
        switch presentation.tone {
        case .neutral: return .gray
        case .trial: return .blue
        case .active: return .green
        case .expired: return .orange
        }
    }
}
