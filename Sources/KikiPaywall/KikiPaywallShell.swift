import AppKit
import KikiDesign
import SwiftUI

/// Reports the height the shell's content wants, so the shell can be as tall
/// as what it holds instead of a number someone guessed.
private struct KikiPaywallNaturalHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct KikiPaywallShell<Header: View, Content: View, Actions: View, Footer: View>: View {
    private let width: CGFloat
    private let minimumHeight: CGFloat
    private let maximumHeight: CGFloat
    private let horizontalPadding: CGFloat
    private let tint: Color
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let header: Header
    private let content: Content
    private let actions: Actions
    private let footer: Footer

    /// Height the shell shows until its content has been measured. Seeded from
    /// the caller's ideal so the sheet opens at its intended size rather than
    /// snapping open on the first layout pass.
    @State private var naturalHeight: CGFloat

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
        self.maximumHeight = max(minimumHeight, maximumHeight)
        self.horizontalPadding = horizontalPadding
        self.tint = tint
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.header = header()
        self.content = content()
        self.actions = actions()
        self.footer = footer()
        _naturalHeight = State(initialValue: idealHeight)
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                if isScrollable {
                    ScrollView(showsIndicators: false) {
                        scrollingArea
                    }
                } else {
                    scrollingArea
                    Spacer(minLength: 0)
                }

                actionsArea
            }

            if showsCloseButton {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2.weight(.medium))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(20)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Close")
            }
        }
        // An unclamped, non-scrolling copy laid out at the real width, purely
        // to report how tall the content is. Hidden and non-interactive, and
        // it never reads the resolved height, so it cannot feed back into it.
        .background(alignment: .top) {
            VStack(spacing: 0) {
                scrollingArea
                actionsArea
            }
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: KikiPaywallNaturalHeightKey.self,
                        value: proxy.size.height
                    )
                }
            )
            .hidden()
            .accessibilityHidden(true)
        }
        .onPreferenceChange(KikiPaywallNaturalHeightKey.self) { height in
            guard height > 0 else { return }
            naturalHeight = height
        }
        .frame(width: width, height: resolvedHeight)
        // Plain material, no tinted wash or top gradient. Those put brand
        // color behind every element on the sheet, which left the CTA and the
        // selected plan card with nothing to stand out against.
        .background {
            KikiMaterialSurface(in: Rectangle(), material: .regularMaterial)
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

    private var resolvedHeight: CGFloat {
        min(max(naturalHeight, minimumHeight), maximumHeight)
    }

    private var isScrollable: Bool {
        naturalHeight > maximumHeight
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
