import AppKit
import SwiftUI

@MainActor
public struct KikiStandardAboutPane: View {
    private let metadata: KikiAppMetadata
    private let icon: NSImage
    private let iconSize: CGFloat
    private let accessStatus: KikiAccessStatusPresentation?
    private let onAccessAction: (@MainActor () -> Void)?
    private let links: KikiStandardAboutLinks
    private let tint: Color

    public init(
        metadata: KikiAppMetadata,
        icon: NSImage? = nil,
        iconSize: CGFloat = 76,
        accessStatus: KikiAccessStatusPresentation? = nil,
        onAccessAction: (@MainActor () -> Void)? = nil,
        links: KikiStandardAboutLinks = KikiStandardAboutLinks(),
        tint: Color = .accentColor
    ) {
        self.metadata = metadata
        self.icon = icon ?? NSApp.applicationIconImage
        self.iconSize = iconSize
        self.accessStatus = accessStatus
        self.onAccessAction = onAccessAction
        self.links = links
        self.tint = tint
    }

    public var body: some View {
        KikiAboutPane(
            appName: metadata.appName,
            versionText: metadata.displayVersion,
            icon: icon,
            iconSize: iconSize,
            status: {
                if let accessStatus {
                    statusRow(for: accessStatus)
                }
            },
            links: {
                ForEach(links.orderedLinks) { link in
                    linkRow(for: link)
                }
                if let copyright = metadata.copyright, copyright.isEmpty == false {
                    Text(copyright)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }

    private func statusRow(for presentation: KikiAccessStatusPresentation) -> some View {
        KikiSettingsStatusRow(
            title: "Status",
            value: presentation.title,
            systemImage: presentation.tone.systemImage,
            tone: presentation.tone.settingsTone,
            tint: tint,
            trailingSystemImage: onAccessAction != nil ? "chevron.right" : nil,
            action: onAccessAction
        )
    }

    @ViewBuilder
    private func linkRow(for link: KikiStandardAboutLink) -> some View {
        switch link.kind {
        case .link:
            KikiSettingsLinkRow(
                title: link.title,
                value: link.value,
                urlString: link.url.absoluteString,
                systemImage: link.systemImage
            )
        case .copy:
            KikiSettingsCopyRow(
                title: link.title,
                value: link.value,
                systemImage: link.systemImage
            )
        }
    }
}
