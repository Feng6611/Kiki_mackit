import AppKit
import KikiDesign
import SwiftUI

/// Default middle content for `KikiOnboardingScaffold`: feature rows plus an
/// optional permission row. Apps with bespoke step bodies provide their own
/// content view instead while the scaffold keeps owning the window chrome.
public struct KikiOnboardingRowsContent: View {
    private let rows: [KikiOnboardingRow]
    private let permissionRow: KikiOnboardingPermissionRow?
    private let tint: Color

    public init(
        rows: [KikiOnboardingRow],
        permissionRow: KikiOnboardingPermissionRow? = nil,
        tint: Color = .accentColor
    ) {
        if rows.count > KikiOnboardingDefaults.maxRowsPerStep {
            assertionFailure(
                "KikiOnboardingRowsContent renders at most \(KikiOnboardingDefaults.maxRowsPerStep) rows; got \(rows.count). Extra rows are dropped."
            )
        }
        self.rows = Array(rows.prefix(KikiOnboardingDefaults.maxRowsPerStep))
        self.permissionRow = permissionRow
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: 12) {
            ForEach(rows) { row in
                KikiOnboardingRowView(row: row, tint: tint)
            }

            if let permissionRow {
                permissionRow
            }
        }
    }
}

public struct KikiOnboardingScaffold<Content: View>: View {
    private let appName: String
    private let title: String
    private let bodyText: String?
    private let appIcon: NSImage?
    private let iconSystemName: String
    private let content: Content
    private let primaryAction: KikiOnboardingAction?
    private let secondaryAction: KikiOnboardingAction?
    private let backAction: KikiOnboardingAction?
    private let skipAction: KikiOnboardingAction?
    private let tint: Color
    private let size: CGSize
    private let stepIndex: Int?
    private let stepCount: Int?

    public init(
        appName: String,
        title: String,
        bodyText: String? = nil,
        appIcon: NSImage? = nil,
        iconSystemName: String = "sparkles",
        primaryAction: KikiOnboardingAction?,
        secondaryAction: KikiOnboardingAction? = nil,
        backAction: KikiOnboardingAction? = nil,
        skipAction: KikiOnboardingAction? = nil,
        tint: Color = .accentColor,
        size: CGSize = KikiOnboardingDefaults.windowSize,
        stepIndex: Int? = nil,
        stepCount: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.appName = appName
        self.title = title
        self.bodyText = bodyText
        self.appIcon = appIcon
        self.iconSystemName = iconSystemName
        self.content = content()
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.backAction = backAction
        self.skipAction = skipAction
        self.tint = tint
        self.size = size
        self.stepIndex = stepIndex
        self.stepCount = stepCount
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 12) {
                        hero

                        VStack(spacing: 6) {
                            Text(title)
                                .font(.title.bold())
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

                    content
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let stepIndex, let stepCount, stepCount > 1 {
                KikiOnboardingProgressDots(
                    count: stepCount,
                    currentIndex: stepIndex,
                    tint: tint
                )
                .padding(.bottom, 14)
            }

            actionArea
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
        }
        .frame(width: size.width, height: size.height)
        .background {
            ZStack {
                KikiMaterialSurface(in: Rectangle(), material: .regularMaterial, tint: tint, tintOpacity: 0.02)
                RadialGradient(
                    colors: [tint.opacity(KikiDesignTokens.Opacity.mediumFill), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 280
                )
            }
            // Cover the full-size transparent title bar as well as the content
            // area. This mirrors Command Reopen and prevents a detached top
            // shadow when AppKit reserves a title-bar safe area.
            .ignoresSafeArea()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(appName) onboarding")
    }

    @ViewBuilder
    private var actionArea: some View {
        if backAction != nil || skipAction != nil {
            navigationBar
        } else {
            stackedActions
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if let skipAction {
                Button(skipAction.title, action: skipAction.action)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .controlSize(.large)
            }

            Spacer(minLength: 0)

            if let backAction {
                Button(backAction.title, action: backAction.action)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }

            if let secondaryAction {
                Button(secondaryAction.title, action: secondaryAction.action)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }

            if let primaryAction {
                Button(primaryAction.title, action: primaryAction.action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(tint)
                    .disabled(!primaryAction.isEnabled)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var stackedActions: some View {
        VStack(spacing: 10) {
            if let primaryAction {
                Button {
                    primaryAction.action()
                } label: {
                    Text(primaryAction.title)
                        .frame(width: KikiOnboardingDefaults.primaryActionWidth)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint)
                .disabled(!primaryAction.isEnabled)
                .keyboardShortcut(.defaultAction)
            }

            if let secondaryAction {
                Button {
                    secondaryAction.action()
                } label: {
                    Text(secondaryAction.title)
                        .frame(width: KikiOnboardingDefaults.primaryActionWidth)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let appIcon {
            Image(nsImage: appIcon)
                .resizable()
                .interpolation(.high)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.heroIcon, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        } else {
            Image(systemName: iconSystemName)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 68, height: 68)
                .background(
                    RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.iconLarge, style: .continuous)
                        .fill(tint.opacity(KikiDesignTokens.Opacity.strongFill))
                )
        }
    }
}

extension KikiOnboardingScaffold where Content == KikiOnboardingRowsContent {
    @available(*, deprecated, message: "Use the Feature initializer with appIcon/progress when needed")
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
            appIcon: nil,
            iconSystemName: iconSystemName,
            rows: rows,
            permissionRow: permissionRow,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            tint: tint
        )
    }

    @available(*, deprecated, message: "Use the Feature initializer with appIcon/progress when needed")
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
        self.init(
            appName: appName,
            title: title,
            bodyText: bodyText,
            appIcon: nil,
            iconSystemName: iconSystemName,
            rows: rows,
            permissionRow: permissionRow,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            tint: tint,
            size: size
        )
    }

    public init(
        appName: String,
        title: String,
        bodyText: String? = nil,
        appIcon: NSImage? = nil,
        iconSystemName: String = "sparkles",
        rows: [KikiOnboardingRow],
        permissionRow: KikiOnboardingPermissionRow? = nil,
        primaryAction: KikiOnboardingAction,
        secondaryAction: KikiOnboardingAction? = nil,
        backAction: KikiOnboardingAction? = nil,
        skipAction: KikiOnboardingAction? = nil,
        tint: Color = .accentColor,
        stepIndex: Int? = nil,
        stepCount: Int? = nil
    ) {
        self.init(
            appName: appName,
            title: title,
            bodyText: bodyText,
            appIcon: appIcon,
            iconSystemName: iconSystemName,
            rows: rows,
            permissionRow: permissionRow,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            backAction: backAction,
            skipAction: skipAction,
            tint: tint,
            size: KikiOnboardingDefaults.windowSize,
            stepIndex: stepIndex,
            stepCount: stepCount
        )
    }

    public init(
        appName: String,
        title: String,
        bodyText: String? = nil,
        appIcon: NSImage? = nil,
        iconSystemName: String = "sparkles",
        rows: [KikiOnboardingRow],
        permissionRow: KikiOnboardingPermissionRow? = nil,
        primaryAction: KikiOnboardingAction,
        secondaryAction: KikiOnboardingAction? = nil,
        backAction: KikiOnboardingAction? = nil,
        skipAction: KikiOnboardingAction? = nil,
        tint: Color = .accentColor,
        size: CGSize,
        stepIndex: Int? = nil,
        stepCount: Int? = nil
    ) {
        self.init(
            appName: appName,
            title: title,
            bodyText: bodyText,
            appIcon: appIcon,
            iconSystemName: iconSystemName,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            backAction: backAction,
            skipAction: skipAction,
            tint: tint,
            size: size,
            stepIndex: stepIndex,
            stepCount: stepCount
        ) {
            KikiOnboardingRowsContent(
                rows: rows,
                permissionRow: permissionRow,
                tint: tint
            )
        }
    }
}
