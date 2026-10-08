import KikiDesign
import SwiftUI

public enum KikiOnboardingStatusTone: Sendable {
    case neutral
    case progress
    case positive
    case attention
    case unavailable
}

public struct KikiOnboardingStatusRow: View {
    private let systemImage: String
    private let title: String
    private let detail: String
    private let statusLabel: String?
    private let tone: KikiOnboardingStatusTone
    private let action: KikiOnboardingAction?
    private let trustNote: String?
    private let tint: Color

    public init(
        systemImage: String,
        title: String,
        detail: String,
        statusLabel: String? = nil,
        tone: KikiOnboardingStatusTone = .neutral,
        action: KikiOnboardingAction? = nil,
        isLoading: Bool = false,
        trustNote: String? = nil,
        tint: Color = .accentColor
    ) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
        self.statusLabel = statusLabel
        self.tone = isLoading ? .progress : tone
        self.action = action
        self.trustNote = trustNote
        self.tint = tint
    }

    public var body: some View {
        Group {
            if let action {
                Button(action: action.action) {
                    content
                }
                .buttonStyle(.plain)
                .disabled(!action.isEnabled)
            } else {
                content
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(action?.title ?? "")
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)

                    if let statusLabel {
                        statusPill(statusLabel)
                    }
                }

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let trustNote {
                    Text(trustNote)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                if let action {
                    Text(action.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if tone == .progress {
                ProgressView()
                    .controlSize(.small)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.panel, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .opacity(action?.isEnabled == false ? KikiDesignTokens.Opacity.disabledContent : 1)
    }

    private func statusPill(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(statusBackground))
    }

    private var statusForeground: Color {
        switch tone {
        case .positive:
            return Color(nsColor: .systemGreen)
        case .attention:
            return Color(nsColor: .systemOrange)
        case .unavailable:
            return .secondary
        case .progress, .neutral:
            return .secondary
        }
    }

    private var statusBackground: Color {
        switch tone {
        case .positive:
            return Color(nsColor: .systemGreen).opacity(KikiDesignTokens.Opacity.badgeFill)
        case .attention:
            return Color(nsColor: .systemOrange).opacity(KikiDesignTokens.Opacity.badgeFill)
        case .unavailable, .progress, .neutral:
            return Color(nsColor: .quaternaryLabelColor)
        }
    }

    private var accessibilityLabel: String {
        [title, statusLabel, detail].compactMap { $0 }.joined(separator: ", ")
    }
}
