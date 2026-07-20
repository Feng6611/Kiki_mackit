import AppKit
import KikiDesign
import SwiftUI

public struct KikiPaywallShell<Header: View, Content: View, Actions: View, Footer: View>: View {
    private let width: CGFloat
    private let height: CGFloat
    private let horizontalPadding: CGFloat
    private let tint: Color
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let header: Header
    private let content: Content
    private let actions: Actions
    private let footer: Footer

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
        self.width = width
        self.height = height
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
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header
                            .padding(.top, 8)
                        content
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 14)
                }

                VStack(spacing: 8) {
                    actions
                    footer
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 14)
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
        .frame(width: width, height: height)
        .background {
            ZStack {
                KikiMaterialSurface(in: Rectangle(), material: .regularMaterial, tint: tint, tintOpacity: 0.025)
                RadialGradient(
                    colors: [tint.opacity(0.05), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 350
                )
            }
        }
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
