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
    private var customStatus: AnyView?
    private var extraLinks: AnyView?
    private var extraSections: AnyView?

    public init(
        metadata: KikiAppMetadata,
        icon: NSImage? = nil,
        iconSize: CGFloat = 76,
        accessStatus: KikiAccessStatusPresentation? = nil,
        onAccessAction: (@MainActor () -> Void)? = nil,
        links: KikiStandardAboutLinks = KikiStandardAboutLinks(),
        tint: Color,
        onOpenLink: ((URL) -> Void)?
    ) {
        self.metadata = metadata
        self.icon = icon ?? KikiApplicationIcon.current
        self.iconSize = iconSize
        self.accessStatus = accessStatus
        self.onAccessAction = onAccessAction
        self.links = links
        self.tint = tint
        self.onOpenLink = onOpenLink
    }

    // Full-signature compatibility for clients storing initializer references.
    public init(metadata: KikiAppMetadata, icon: NSImage? = nil, iconSize: CGFloat = 76,
                accessStatus: KikiAccessStatusPresentation? = nil, onAccessAction: (@MainActor () -> Void)? = nil,
                links: KikiStandardAboutLinks = KikiStandardAboutLinks(), onOpenLink: ((URL) -> Void)? = nil) {
        self.init(metadata: metadata, icon: icon, iconSize: iconSize, accessStatus: accessStatus,
                  onAccessAction: onAccessAction, links: links, tint: KikiDesignColor.proAccent, onOpenLink: onOpenLink)
    }

    public init(metadata: KikiAppMetadata, icon: NSImage? = nil, iconSize: CGFloat = 76,
                accessStatus: KikiAccessStatusPresentation? = nil, onAccessAction: (@MainActor () -> Void)? = nil,
                links: KikiStandardAboutLinks = KikiStandardAboutLinks(), tint: Color) {
        self.init(metadata: metadata, icon: icon, iconSize: iconSize, accessStatus: accessStatus,
                  onAccessAction: onAccessAction, links: links, tint: tint, onOpenLink: nil)
    }

    /// Replaces the standard access row with caller-owned status content.
    /// Repeated calls replace the previous slot content.
    /// Omit this modifier to retain the configured access status and action.
    public func statusContent<Status: View>(@ViewBuilder _ content: () -> Status) -> Self {
        var pane = self
        pane.customStatus = AnyView(content())
        return pane
    }

    /// Repeated calls replace the previous slot content.
    /// Adds rows after the standard links and before copyright.
    public func additionalLinks<Links: View>(@ViewBuilder _ content: () -> Links) -> Self {
        var pane = self
        pane.extraLinks = AnyView(content())
        return pane
    }

    /// Repeated calls replace the previous slot content.
    /// Adds sections after the standard sections, within the same scrolling form.
    public func additionalSections<Sections: View>(@ViewBuilder _ content: () -> Sections) -> Self {
        var pane = self
        pane.extraSections = AnyView(content())
        return pane
    }

    public var body: some View {
        KikiAboutPane(
            appName: metadata.appName,
            versionText: metadata.displayVersion,
            icon: icon,
            iconSize: iconSize,
            status: {
                if let customStatus {
                    customStatus
                } else if let accessStatus {
                    statusRow(for: accessStatus)
                }
            },
            links: {
                ForEach(links.orderedLinks) { link in
                    linkRow(for: link)
                }
                extraLinks
                if let copyright = metadata.copyright, copyright.isEmpty == false {
                    Text(copyright)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        )
        .additionalSections { extraSections }
    }

    private func statusRow(for presentation: KikiAccessStatusPresentation) -> some View {
        KikiAccessStatusCard(presentation: presentation, tint: tint, action: onAccessAction)
    }

    // Shared by rendering and regression tests: copy rows must retain the
    // native copy action even when the host intercepts URL navigation.
    func customLinkAction(for link: KikiStandardAboutLink) -> (() -> Void)? {
        guard link.kind == .link, let onOpenLink else { return nil }
        return { onOpenLink(link.url) }
    }

    @ViewBuilder
    private func linkRow(for link: KikiStandardAboutLink) -> some View {
        switch link.kind {
        case .link:
            KikiSettingsLinkRow(
                title: link.title, value: link.value,
                urlString: link.url.absoluteString,
                systemImage: link.systemImage ?? "link",
                action: customLinkAction(for: link)
            )
        case .copy:
            KikiSettingsCopyRow(
                title: link.title, value: link.value,
                systemImage: link.systemImage ?? "envelope"
            )
        }
    }
}
