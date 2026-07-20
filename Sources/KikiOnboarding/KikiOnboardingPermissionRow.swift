import AppKit
import KikiAuthorization
import KikiDesign
import SwiftUI

public struct KikiOnboardingPermissionRow: View {
    private let panel: KikiAuthorizationPanel
    private let instruction: String
    private let tint: Color
    @State private var refreshID = UUID()

    public init(
        panel: KikiAuthorizationPanel,
        instruction: String,
        tint: Color = .accentColor
    ) {
        self.panel = panel
        self.instruction = instruction
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

                        Text(panel.isAuthorized ? "Allowed" : "Needs Permission")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(panel.isAuthorized ? Color(nsColor: .systemGreen) : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill((panel.isAuthorized ? Color(nsColor: .systemGreen) : .orange).opacity(KikiDesignTokens.Opacity.badgeFill))
                            )
                    }

                    Text(instruction)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
}
