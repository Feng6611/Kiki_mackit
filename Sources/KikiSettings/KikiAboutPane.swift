import AppKit
import SwiftUI

public struct KikiAppIdentityView: View {
    private let appName: String
    private let versionText: String
    private let icon: NSImage
    private let iconSize: CGFloat

    public init(
        appName: String,
        versionText: String,
        icon: NSImage = NSApp.applicationIconImage,
        iconSize: CGFloat = 76
    ) {
        self.appName = appName
        self.versionText = versionText
        self.icon = icon
        self.iconSize = iconSize
    }

    public var body: some View {
        VStack(spacing: KikiSettingsSpacing.sm) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)

            Text(appName)
                .font(.system(size: 20, weight: .semibold))

            Text(versionText)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

public struct KikiAboutPane<StatusContent: View, LinksContent: View>: View {
    private let appName: String
    private let versionText: String
    private let icon: NSImage
    private let iconSize: CGFloat
    private let statusContent: StatusContent
    private let linksContent: LinksContent

    public init(
        appName: String,
        versionText: String,
        icon: NSImage = NSApp.applicationIconImage,
        iconSize: CGFloat = 76,
        @ViewBuilder status: () -> StatusContent,
        @ViewBuilder links: () -> LinksContent
    ) {
        self.appName = appName
        self.versionText = versionText
        self.icon = icon
        self.iconSize = iconSize
        self.statusContent = status()
        self.linksContent = links()
    }

    public var body: some View {
        Form {
            Section {
                KikiAppIdentityView(
                    appName: appName,
                    versionText: versionText,
                    icon: icon,
                    iconSize: iconSize
                )
                .padding(.vertical, KikiSettingsSpacing.xl)
                .listRowBackground(KikiSettingsColors.background)
            }

            Section {
                statusContent
            }
            .listRowBackground(KikiSettingsColors.sectionBackground)

            Section {
                linksContent
            }
            .listRowBackground(KikiSettingsColors.sectionBackground)
        }
        .kikiSettingsPaneChrome()
    }
}
