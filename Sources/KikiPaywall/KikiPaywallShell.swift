import AppKit
import KikiDesign
import SwiftUI

public struct KikiPaywallShell<Header: View, Content: View, Actions: View, Footer: View>: View {
    private let width: CGFloat
    private let minimumHeight: CGFloat
    private let idealHeight: CGFloat
    private let maximumHeight: CGFloat
    private let horizontalPadding: CGFloat
    private let tint: Color
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let header: Header
    private let content: Content
    private let actions: Actions
    private let footer: Footer

    /// A shell of a fixed height, for content whose shape does not change.
    public init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        height: CGFloat = KikiPaywallDefaults.sheetHeight,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(
            width: width,
            minimumHeight: height,
            idealHeight: height,
            maximumHeight: height,
            horizontalPadding: horizontalPadding,
            tint: tint,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            header: header,
            content: content,
            actions: actions,
            footer: footer
        )
    }

    /// A shell that takes the height its content needs, within bounds.
    ///
    /// Use this when the same shell renders several shapes — a paywall gains
    /// and loses stats, plans and secondary buttons with the access state, and
    /// a single fixed height either clips the tallest arrangement or leaves a
    /// void under the shortest.
    ///
    /// - Parameters:
    ///   - minimumHeight: floor, so a nearly empty shell still reads as a sheet.
    ///   - idealHeight: shown until the content reports its own height.
    ///   - maximumHeight: ceiling. Content taller than this scrolls; below it,
    ///     nothing scrolls and nothing is hidden.
    public init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        minimumHeight: CGFloat,
        idealHeight: CGFloat,
        maximumHeight: CGFloat,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder footer: () -> Footer
    ) {
        self.width = width
        self.minimumHeight = min(minimumHeight, maximumHeight)
        self.idealHeight = idealHeight
        self.maximumHeight = max(minimumHeight, maximumHeight)
        self.horizontalPadding = horizontalPadding
        self.tint = tint
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.header = header()
        self.content = content()
        self.actions = actions()
        self.footer = footer()
    }

    public var body: some View {
        // The card chrome — width, content-measured height, material, and the
        // close control — is the shared KikiSheetShell. The paywall keeps only
        // what is its own: how the header, stats, plans and actions stack.
        KikiSheetShell(
            width: width,
            minimumHeight: minimumHeight,
            idealHeight: idealHeight,
            maximumHeight: maximumHeight,
            showsCloseButton: showsCloseButton,
            onClose: onClose
        ) {
            scrollingArea
        } footer: {
            actionsArea
        }
    }

    private var scrollingArea: some View {
        VStack(spacing: 14) {
            header
                .padding(.top, 8)
            content
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 14)
    }

    private var actionsArea: some View {
        VStack(spacing: 8) {
            actions
            footer
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 14)
    }

}

public extension KikiPaywallShell where Actions == EmptyView, Footer == EmptyView {
    init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        height: CGFloat = KikiPaywallDefaults.sheetHeight,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            width: width,
            height: height,
            horizontalPadding: horizontalPadding,
            tint: tint,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            header: header,
            content: content,
            actions: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

public struct KikiPaywallHeader: View {
    private let title: String
    private let subtitle: String
    private let icon: NSImage?
    private let iconSize: CGFloat

    public init(
        title: String,
        subtitle: String,
        icon: NSImage? = nil,
        iconSize: CGFloat = 80
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon ?? NSApplication.shared.applicationIconImage
        self.iconSize = iconSize
    }

    public var body: some View {
        VStack(spacing: 12) {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.iconLarge, style: .continuous))
                    .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
            }

            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
