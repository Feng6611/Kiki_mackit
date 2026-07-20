import AppKit
import Foundation
import QuartzCore

@MainActor
final class KikiAuthorizationOverlayWindowController: NSWindowController {
    private static let baseWindowSize = NSSize(width: 440, height: 138)
    private static let trustNoteAdditionalHeight: CGFloat = 26

    private let windowSize: NSSize

    init(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?,
        trustNote: String?,
        onDismiss: @escaping () -> Void
    ) {
        let size: NSSize
        if trustNote?.isEmpty == false {
            size = NSSize(
                width: Self.baseWindowSize.width,
                height: Self.baseWindowSize.height + Self.trustNoteAdditionalHeight
            )
        } else {
            size = Self.baseWindowSize
        }
        self.windowSize = size

        let window = KikiAuthorizationPanelWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        configure(window)
        window.contentView = KikiAuthorizationOverlayView(
            hostApp: hostApp,
            panel: panel,
            instruction: instruction,
            trustNote: trustNote,
            onDismiss: onDismiss
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func close() {
        window?.orderOut(nil)
        super.close()
    }

    func present(
        from sourceFrameInScreen: CGRect?,
        settingsFrame: CGRect,
        visibleFrame: CGRect
    ) {
        guard let window else {
            return
        }

        let targetFrame = NSRect(
            origin: anchoredOrigin(settingsFrame: settingsFrame, visibleFrame: visibleFrame),
            size: windowSize
        )

        guard let sourceFrameInScreen, sourceFrameInScreen.width > 1, sourceFrameInScreen.height > 1 else {
            window.alphaValue = 1
            window.setFrame(targetFrame, display: false)
            window.orderFrontRegardless()
            return
        }

        window.alphaValue = 0.9
        window.setFrame(sourceFrameInScreen, display: false)
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(targetFrame, display: true)
            window.animator().alphaValue = 1
        }
    }

    func updatePosition(settingsFrame: CGRect, visibleFrame: CGRect) {
        guard let window else {
            return
        }

        window.setFrameOrigin(anchoredOrigin(settingsFrame: settingsFrame, visibleFrame: visibleFrame))
        window.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func configure(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.animationBehavior = .none
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]
    }

    private func anchoredOrigin(settingsFrame: CGRect, visibleFrame: CGRect) -> NSPoint {
        let sidebarWidth: CGFloat = 170
        let margin: CGFloat = 10
        let contentMinX = settingsFrame.minX + sidebarWidth
        let contentWidth = max(settingsFrame.width - sidebarWidth, windowSize.width)
        let preferredX = contentMinX + ((contentWidth - windowSize.width) / 2)
        let preferredY = settingsFrame.minY + 14

        let minX = visibleFrame.minX + margin
        let maxX = visibleFrame.maxX - windowSize.width - margin
        let minY = visibleFrame.minY + margin
        let maxY = visibleFrame.maxY - windowSize.height - margin

        return NSPoint(
            x: min(max(preferredX, minX), maxX),
            y: min(max(preferredY, minY), maxY)
        )
    }
}

private final class KikiAuthorizationPanelWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
