import AppKit
import SwiftUI

public struct KikiStandardAboutPane: View {
    private let metadata: KikiAppMetadata
    private let icon: NSImage
    private let iconSize: CGFloat
    private let accessStatus: KikiAccessStatusPresentation?
    private let onAccessAction: (@MainActor () -> Void)?
    private let links: KikiStandardAboutLinks
    private let onOpenLink: ((URL) -> Void)?

    public init(
        metadata: KikiAppMetadata,
        icon: NSImage = NSApp.applicationIconImage,
        iconSize: CGFloat = 76,
        accessStatus: KikiAccessStatusPresentation? = nil,
        onAccessAction: (@MainActor () -> Void)? = nil,
        links: KikiStandardAboutLinks = KikiStandardAboutLinks(),
        onOpenLink: ((URL) -> Void)? = nil
    ) {
        self.metadata = metadata
        self.icon = icon
        self.iconSize = iconSize
        self.accessStatus = accessStatus
        self.onAccessAction = onAccessAction
        self.links = links
        self.onOpenLink = onOpenLink
    }

    public var body: some View {
        KikiAboutPane(
            appName: metadata.appName,
            versionText: metadata.displayVersion,
            icon: icon,
            iconSize: iconSize,
            status: {
                if let accessStatus {
                    KikiAccessStatusCard(presentation: accessStatus, action: onAccessAction)
                        .padding(.vertical, 4)
                }
            },
            links: {
                ForEach(links.orderedLinks) { link in
                    Button {
                        openLink(link.url)
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
                }
                if let copyright = metadata.copyright, copyright.isEmpty == false {
                    Text(copyright)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }

    private func openLink(_ url: URL) {
        if let onOpenLink {
            onOpenLink(url)
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}
