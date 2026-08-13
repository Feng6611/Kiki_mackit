import SwiftUI

/// Geometry and feel of a card sheet. Defaults suit a Settings-sized window;
/// larger hosts can widen the insets rather than let the card grow to the
/// window's edges.
public struct KikiCardSheetStyle: Equatable, Sendable {
    public let cornerRadius: CGFloat
    public let horizontalInset: CGFloat
    public let bottomInset: CGFloat
    /// Share of the host's height the card may occupy before its own content
    /// has to scroll. A card that reaches the top edge stops reading as a
    /// layer over the window.
    public let maximumHeightFraction: CGFloat
    public let scrimOpacity: Double

    public init(
        cornerRadius: CGFloat = KikiDesignTokens.CornerRadius.elevatedCard,
        horizontalInset: CGFloat = 16,
        bottomInset: CGFloat = 16,
        maximumHeightFraction: CGFloat = 0.92,
        scrimOpacity: Double = 0.28
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalInset = horizontalInset
        self.bottomInset = bottomInset
        self.maximumHeightFraction = maximumHeightFraction
        self.scrimOpacity = scrimOpacity
    }

    public static let `default` = KikiCardSheetStyle()
}

/// A card that rises from the bottom of the view it is attached to, over a
/// scrim that can dismiss it.
///
/// Not an AppKit sheet. A sheet drops from the title bar, is sized in absolute
/// points against a window whose height it cannot see, and is modal — clicking
/// beside it beeps. This presents inside the host view instead, so the card
/// cannot overhang the window, the way out is the obvious one (click beside
/// it, or Escape), and the motion says where it came from and where it will
/// go back to.
///
/// This is presentation infrastructure, not a reading-content policy. A help
/// card can allow background dismissal while a paywall can reuse the same
/// bottom-card geometry with background dismissal disabled.
private struct KikiCardSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let style: KikiCardSheetStyle
    let showsCloseButton: Bool
    let allowsBackgroundDismiss: Bool
    let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    ZStack(alignment: .bottom) {
                        if isPresented {
                            scrim
                            card(maximumHeight: proxy.size.height * style.maximumHeightFraction)
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                    .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isPresented)
                }
                // Escape belongs to the card while it is up, and the card is
                // the frontmost thing in the window, so the host's own exit
                // handling stays untouched when it is not.
                .onExitCommand { dismiss() }
            }
    }

    private var scrim: some View {
        Rectangle()
            .fill(.black.opacity(style.scrimOpacity))
            .contentShape(Rectangle())
            .onTapGesture {
                guard allowsBackgroundDismiss else { return }
                dismiss()
            }
            .transition(.opacity)
            .accessibilityHidden(!allowsBackgroundDismiss)
            .accessibilityLabel(Text("Close", bundle: .main))
            .accessibilityAddTraits(allowsBackgroundDismiss ? .isButton : [])
            .accessibilityAction {
                guard allowsBackgroundDismiss else { return }
                dismiss()
            }
    }

    private func card(maximumHeight: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)

        return ZStack(alignment: .topTrailing) {
            sheetContent()

            if showsCloseButton {
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2.weight(.medium))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(16)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel(Text("Close", bundle: .main))
            }
        }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: max(0, maximumHeight))
            .background {
                KikiMaterialSurface(in: shape)
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    Color(nsColor: .separatorColor)
                        .opacity(KikiDesignTokens.Separator.mutedOpacity),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.22), radius: 18, y: 6)
            .padding(.horizontal, style.horizontalInset)
            .padding(.bottom, style.bottomInset)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func dismiss() {
        guard isPresented else {
            return
        }
        isPresented = false
    }
}

public extension View {
    /// Presents `content` as a card rising from the bottom of this view,
    /// dismissed by clicking the scrim or pressing Escape.
    ///
    /// Attach it to the largest view the card should be able to cover —
    /// usually the window's whole content, not one pane inside it. Attaching
    /// it further in leaves the card competing for height with the chrome
    /// above the pane.
    func kikiCardSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        style: KikiCardSheetStyle = .default,
        showsCloseButton: Bool = true,
        allowsBackgroundDismiss: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            KikiCardSheetModifier(
                isPresented: isPresented,
                style: style,
                showsCloseButton: showsCloseButton,
                allowsBackgroundDismiss: allowsBackgroundDismiss,
                sheetContent: content
            )
        )
    }
}
