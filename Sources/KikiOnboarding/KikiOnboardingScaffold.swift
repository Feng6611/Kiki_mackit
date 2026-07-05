import KikiDesign
import SwiftUI

public struct KikiOnboardingScaffold: View {
    private let appName: String
    private let title: String
    private let bodyText: String?
    private let iconSystemName: String
    private let rows: [KikiOnboardingRow]
    private let permissionRow: KikiOnboardingPermissionRow?
    private let primaryAction: KikiOnboardingAction
    private let secondaryAction: KikiOnboardingAction?
    private let tint: Color
    private let size: CGSize

    public init(
        appName: String,
        title: String,
        bodyText: String? = nil,
        iconSystemName: String = "sparkles",
        rows: [KikiOnboardingRow],
        permissionRow: KikiOnboardingPermissionRow? = nil,
        primaryAction: KikiOnboardingAction,
        secondaryAction: KikiOnboardingAction? = nil,
        tint: Color = .accentColor
    ) {
        self.init(
            appName: appName,
            title: title,
            bodyText: bodyText,
            iconSystemName: iconSystemName,
            rows: rows,
            permissionRow: permissionRow,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            tint: tint,
            size: KikiOnboardingDefaults.windowSize
        )
    }

    public init(
        appName: String,
        title: String,
        bodyText: String? = nil,
        iconSystemName: String = "sparkles",
        rows: [KikiOnboardingRow],
        permissionRow: KikiOnboardingPermissionRow? = nil,
        primaryAction: KikiOnboardingAction,
        secondaryAction: KikiOnboardingAction? = nil,
        tint: Color = .accentColor,
        size: CGSize
    ) {
        self.appName = appName
        self.title = title
        self.bodyText = bodyText
        self.iconSystemName = iconSystemName
        self.rows = Array(rows.prefix(3))
        self.permissionRow = permissionRow
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(tint)
                        )

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        if let bodyText {
                            Text(bodyText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(spacing: 12) {
                    ForEach(rows) { row in
                        KikiOnboardingRowView(row: row, tint: tint)
                    }

                    if let permissionRow {
                        permissionRow
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(28)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button {
                    primaryAction.action()
                } label: {
                    Text(primaryAction.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                if let secondaryAction {
                    Button {
                        secondaryAction.action()
                    } label: {
                        Text(secondaryAction.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(width: size.width, height: size.height)
        .background {
            ZStack {
                KikiMaterialSurface(in: Rectangle(), material: .regularMaterial, tint: tint, tintOpacity: 0.02)
                RadialGradient(
                    colors: [tint.opacity(0.08), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 280
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(appName) onboarding")
    }
}
