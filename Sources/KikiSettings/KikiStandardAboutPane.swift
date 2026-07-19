import AppKit
import KikiDesign
import SwiftUI

@preconcurrency @MainActor
public struct KikiStandardAboutPane: View {
    private let metadata: KikiAppMetadata
    private let icon: NSImage
    private let iconSize: CGFloat
    private let accessStatus: KikiAccessStatusPresentation?
    private let onAccessAction: (@MainActor () -> Void)?
    private let links: KikiStandardAboutLinks
    private let tint: Color
    private let onOpenLink: ((URL) -> Void)?

    public init(
        metadata: KikiAppMetadata,
        icon: NSImage? = nil,
        iconSize: CGFloat = 76,
        accessStatus: KikiAccessStatusPresentation? = nil,
        onAccessAction: (@MainActor () -> Void)? = nil,
        links: KikiStandardAboutLinks = KikiStandardAboutLinks(),
        onOpenLink: ((URL) -> Void)? = nil
    ) {
        self.metadata = metadata
        self.icon = icon ?? KikiApplicationIcon.current
        self.iconSize = iconSize
        self.accessStatus = accessStatus
        self.onAccessAction = onAccessAction
        self.links = links
        self.tint = KikiDesignColor.proAccent
        self.onOpenLink = onOpenLink
    }

    public init(
        metadata: KikiAppMetadata,
        icon: NSImage? = nil,
        iconSize: CGFloat = 76,
        accessStatus: KikiAccessStatusPresentation? = nil,
        onAccessAction: (@MainActor () -> Void)? = nil,
        links: KikiStandardAboutLinks = KikiStandardAboutLinks(),
        tint: Color
    ) {
        self.metadata = metadata
        self.icon = icon ?? KikiApplicationIcon.current
        self.iconSize = iconSize
        self.accessStatus = accessStatus
        self.onAccessAction = onAccessAction
        self.links = links
        self.tint = tint
        self.onOpenLink = nil
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
            systemImage: "info.circle",
            valueSystemImage: presentation.tone == .neutral ? nil : presentation.tone.systemImage,
            tone: presentation.tone.settingsTone,
            tint: tint,
            showsBadge: false,
            trailingSystemImage: onAccessAction != nil ? "chevron.right" : nil,
            action: onAccessAction
        )
    }

    @ViewBuilder
    private func linkRow(for link: KikiStandardAboutLink) -> some View {
        if let onOpenLink {
            Button {
                onOpenLink(link.url)
            } label: {
                HStack(spacing: KikiSettingsSpacing.sm) {
                    if let systemImage = link.systemImage {
                        Image(systemName: systemImage)
                            .frame(width: 18)
                            .foregroundStyle(.secondary)
                    }
                    Text(link.title)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        } else {
        switch link.kind {
        case .link:
            KikiSettingsLinkRow(
                title: link.title,
                value: link.value,
                urlString: link.url.absoluteString,
                systemImage: link.systemImage ?? "link"
            )
        case .copy:
            KikiSettingsCopyRow(
                title: link.title,
                value: link.value,
                systemImage: link.systemImage ?? "envelope"
            )
        }
        }
    }
}
