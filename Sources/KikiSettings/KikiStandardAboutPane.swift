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

    public init(
        metadata: KikiAppMetadata,
        icon: NSImage? = nil,
        iconSize: CGFloat = 76,
        accessStatus: KikiAccessStatusPresentation? = nil,
        onAccessAction: (@MainActor () -> Void)? = nil,
        links: KikiStandardAboutLinks = KikiStandardAboutLinks()
    ) {
        self.metadata = metadata
        self.icon = icon ?? NSApp.applicationIconImage
        self.iconSize = iconSize
        self.accessStatus = accessStatus
        self.onAccessAction = onAccessAction
        self.links = links
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
            systemImage: statusSymbol(for: presentation.tone),
            tone: statusTone(for: presentation.tone),
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

    private func statusSymbol(for tone: KikiAccessStatusTone) -> String {
        switch tone {
        case .neutral: return "info.circle"
        case .trial: return "clock"
        case .active: return "checkmark.seal"
        case .expired: return "exclamationmark.triangle"
        }
    }

    private func statusTone(for tone: KikiAccessStatusTone) -> KikiSettingsStatusTone {
        switch tone {
        case .neutral: return .neutral
        case .trial: return .accent
        case .active: return .success
        case .expired: return .warning
        }
    }
}
