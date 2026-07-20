import AppKit
import KikiAuthorization
import KikiDesign
import SwiftUI

public struct KikiOnboardingPermissionRow: View {
    private let panel: KikiAuthorizationPanel
    private let instruction: String
    private let trustNote: String?
    private let authorizedLabel: String
    private let unauthorizedLabel: String
    private let tint: Color
    @State private var refreshID = UUID()

    public init(
        panel: KikiAuthorizationPanel,
        instruction: String,
        trustNote: String? = nil,
        authorizedLabel: String = "Allowed",
        unauthorizedLabel: String = "Not connected",
        tint: Color = .accentColor
    ) {
        self.panel = panel
        self.instruction = instruction
        self.trustNote = trustNote
        self.authorizedLabel = authorizedLabel
        self.unauthorizedLabel = unauthorizedLabel
        self.tint = tint
    }

    public var body: some View {
        Button {
            KikiAuthorizationAssistant.shared.present(
                panel: panel,
                instruction: instruction
            )
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: panel.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(panel.title)
                            .font(.headline)

                        statusPill
                    }

                    Text(instruction)
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
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.panel, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
        .buttonStyle(.plain)
        .id(refreshID)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshID = UUID()
        }
    }

    /// Only the authorized state gets a colored pill; unauthorized reads as
    /// a subtle neutral status. Permission absence is common at first launch
    /// and doesn't warrant a warning-tone treatment that pulls the eye away
    /// from the primary Onboarding action.
    @ViewBuilder
    private var statusPill: some View {
        if panel.isAuthorized {
            Text(authorizedLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(nsColor: .systemGreen))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .systemGreen).opacity(KikiDesignTokens.Opacity.badgeFill))
                )
        } else {
            Text(unauthorizedLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .quaternaryLabelColor))
                )
        }
    }
}
