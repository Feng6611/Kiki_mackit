import SwiftUI

/// Reports the height the shell's content wants, so the shell can be as tall as
/// what it holds instead of a number someone guessed.
private struct KikiSheetNaturalHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct KikiSheetFooterHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// The card chrome shared by every Kiki sheet: a fixed width, a height that
/// follows its content within bounds, a plain material background, and one
/// close control in the top-trailing corner.
///
/// This is the base the paywall and the shortcuts list both sit on, so a sheet
/// added later inherits the same size behaviour and the same way out rather
/// than reinventing either. Present it inside SwiftUI's `.sheet` — the shell
/// draws the card; the sheet supplies the scrim and the modal presentation.
///
/// `content` is the scrolling region and `footer` is pinned below it, both
/// caller-padded. A sheet with no pinned actions omits the footer and leans on
/// the close button.
public struct KikiSheetShell<Content: View, Footer: View>: View {
    private let width: CGFloat
    private let minimumHeight: CGFloat
    private let maximumHeight: CGFloat
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let content: Content
    private let footer: Footer

    /// Shown until the content reports its own height, so the sheet opens at
    /// its intended size instead of snapping open on the first layout pass.
    @State private var naturalHeight: CGFloat
    @State private var footerHeight: CGFloat = 0

    public init(
        width: CGFloat,
        minimumHeight: CGFloat,
        idealHeight: CGFloat,
        maximumHeight: CGFloat,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.width = width
        self.minimumHeight = min(minimumHeight, maximumHeight)
        self.maximumHeight = max(minimumHeight, maximumHeight)
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.content = content()
        self.footer = footer()
        _naturalHeight = State(initialValue: idealHeight)
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Keep the same hierarchy as content grows or shrinks. Measuring
                // the mounted scroll document avoids duplicate lifecycle work.
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) { content }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(contentHeightReader)
                }
                .onPreferenceChange(KikiSheetNaturalHeightKey.self) { naturalHeight = $0 }
                .frame(height: max(0, resolvedHeight - resolvedFooterHeight))

                // Normal footers stay pinned at their natural height. An unusually
                // tall footer scrolls within half the shell, keeping both regions usable.
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) { footer }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(footerHeightReader)
                }
                .onPreferenceChange(KikiSheetFooterHeightKey.self) { footerHeight = $0 }
                .frame(height: resolvedFooterHeight)
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
                .accessibilityLabel(Text("Close", bundle: .main))
            }
        }
        .frame(width: width, height: resolvedHeight)
        .background {
            KikiMaterialSurface(in: Rectangle(), material: .regularMaterial)
        }
    }

    private var resolvedHeight: CGFloat {
        min(max(naturalHeight + footerHeight, minimumHeight), maximumHeight)
    }

    private var resolvedFooterHeight: CGFloat {
        min(footerHeight, resolvedHeight / 2)
    }

    private var contentHeightReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: KikiSheetNaturalHeightKey.self, value: proxy.size.height)
        }
    }

    private var footerHeightReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: KikiSheetFooterHeightKey.self, value: proxy.size.height)
        }
    }
}

public extension KikiSheetShell where Footer == EmptyView {
    init(
        width: CGFloat,
        minimumHeight: CGFloat,
        idealHeight: CGFloat,
        maximumHeight: CGFloat,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            width: width,
            minimumHeight: minimumHeight,
            idealHeight: idealHeight,
            maximumHeight: maximumHeight,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            content: content,
            footer: { EmptyView() }
        )
    }
}
