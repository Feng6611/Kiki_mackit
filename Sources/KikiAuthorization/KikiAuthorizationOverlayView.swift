import AppKit
import Foundation
import QuartzCore

@MainActor
final class KikiAuthorizationOverlayView: NSView, NSPasteboardItemDataProvider, NSDraggingSource {
    private let hostApp: KikiAuthorizationHostApp
    private let bundleURLData: Data
    private let tint: NSColor
    private var chipView: KikiAuthorizationAppDragSourceView?
    private var trackingArea: NSTrackingArea?

    init(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?,
        trustNote: String?,
        tint: NSColor
    ) {
        self.hostApp = hostApp
        self.bundleURLData = hostApp.bundleURL.dataRepresentation
        self.tint = tint
        super.init(frame: NSRect(x: 0, y: 0, width: 380, height: 132))
        autoresizingMask = [.width, .height]
        buildView(
            hostApp: hostApp,
            panel: panel,
            instruction: instruction,
            trustNote: trustNote,
            tint: tint
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?,
        trustNote: String?,
        tint: NSColor
    ) {
        let materialView = NSVisualEffectView()
        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.material = .popover
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.wantsLayer = true
        materialView.layer?.cornerRadius = 12
        materialView.layer?.masksToBounds = true
        // No border: NSPanel's own drop shadow (window.hasShadow = true)
        // grounds the popover. A visible border here read as a dark ring
        // against the material — the previous separatorColor.35 was picking
        // up a "dirty" edge in both light and dark appearances.
        addSubview(materialView)

        // Radial tint wash at the top gives the popover a subtle "glow from
        // the accent color" feel without adding a full colored surface. Same
        // pattern used in KikiPaywallShell so Kiki chrome shares one visual
        // vocabulary across features.
        let tintGlowLayer = CAGradientLayer()
        tintGlowLayer.type = .radial
        tintGlowLayer.colors = [
            tint.withAlphaComponent(0.10).cgColor,
            tint.withAlphaComponent(0.0).cgColor,
        ]
        tintGlowLayer.locations = [0.0, 1.0]
        tintGlowLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        tintGlowLayer.endPoint = CGPoint(x: 1.05, y: 0.0)
        let glowHost = NSView()
        glowHost.translatesAutoresizingMaskIntoConstraints = false
        glowHost.wantsLayer = true
        glowHost.layer?.addSublayer(tintGlowLayer)
        glowHost.layer?.masksToBounds = true
        materialView.addSubview(glowHost)

        // Track the glow layer to match host bounds on layout.
        let glowTrackingCoordinator = KikiOverlayGlowLayoutBridge(
            host: glowHost,
            layer: tintGlowLayer
        )
        objc_setAssociatedObject(
            glowHost,
            &Self.glowBridgeKey,
            glowTrackingCoordinator,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        // Small upward chevron in the tint color communicates "the setting
        // you want is above this overlay" and threads the accent color
        // through the top of the chrome. Not a full NSPopover attachment
        // (which would require walking System Settings' AX tree to find
        // the list-header rect — brittle across macOS versions).
        let directionIndicator = NSImageView()
        directionIndicator.translatesAutoresizingMaskIntoConstraints = false
        directionIndicator.image = NSImage(systemSymbolName: "chevron.up", accessibilityDescription: nil)
        directionIndicator.symbolConfiguration = .init(pointSize: 10, weight: .semibold)
        directionIndicator.contentTintColor = tint.withAlphaComponent(0.65)
        materialView.addSubview(directionIndicator)

        // Small tinted disc behind the permission icon — one color moment
        // that tells users which permission this overlay is about without
        // dominating the layout the way the previous 34pt block did.
        let iconDisc = NSView()
        iconDisc.translatesAutoresizingMaskIntoConstraints = false
        iconDisc.wantsLayer = true
        iconDisc.layer?.cornerRadius = 11
        iconDisc.layer?.backgroundColor = tint.withAlphaComponent(0.14).cgColor
        materialView.addSubview(iconDisc)

        let iconGlyph = NSImageView()
        iconGlyph.translatesAutoresizingMaskIntoConstraints = false
        iconGlyph.image = NSImage(systemSymbolName: panel.systemImage, accessibilityDescription: panel.title)
        iconGlyph.symbolConfiguration = .init(pointSize: 12, weight: .semibold)
        iconGlyph.contentTintColor = tint
        iconDisc.addSubview(iconGlyph)

        let headingLabel = NSTextField(labelWithString: "Allow \(panel.title)")
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headingLabel.textColor = .labelColor
        materialView.addSubview(headingLabel)

        let bodyLabel = NSTextField(labelWithString: instructionText(
            hostApp: hostApp,
            panel: panel,
            override: instruction
        ))
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.maximumNumberOfLines = 2
        materialView.addSubview(bodyLabel)

        let trustNoteLabel: NSTextField?
        if let trustNote, trustNote.isEmpty == false {
            let label = NSTextField(labelWithString: trustNote)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .systemFont(ofSize: 11, weight: .regular)
            label.textColor = .tertiaryLabelColor
            label.lineBreakMode = .byWordWrapping
            label.maximumNumberOfLines = 2
            materialView.addSubview(label)
            trustNoteLabel = label
        } else {
            trustNoteLabel = nil
        }

        let dragSource = KikiAuthorizationAppDragSourceView(hostApp: hostApp, tint: tint)
        materialView.addSubview(dragSource)
        chipView = dragSource

        var constraints: [NSLayoutConstraint] = [
            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),

            glowHost.leadingAnchor.constraint(equalTo: materialView.leadingAnchor),
            glowHost.trailingAnchor.constraint(equalTo: materialView.trailingAnchor),
            glowHost.topAnchor.constraint(equalTo: materialView.topAnchor),
            glowHost.bottomAnchor.constraint(equalTo: materialView.bottomAnchor),

            directionIndicator.centerXAnchor.constraint(equalTo: materialView.centerXAnchor),
            directionIndicator.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 6),

            iconDisc.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 14),
            iconDisc.centerYAnchor.constraint(equalTo: headingLabel.centerYAnchor),
            iconDisc.widthAnchor.constraint(equalToConstant: 22),
            iconDisc.heightAnchor.constraint(equalToConstant: 22),

            iconGlyph.centerXAnchor.constraint(equalTo: iconDisc.centerXAnchor),
            iconGlyph.centerYAnchor.constraint(equalTo: iconDisc.centerYAnchor),
            iconGlyph.widthAnchor.constraint(equalToConstant: 14),
            iconGlyph.heightAnchor.constraint(equalToConstant: 14),

            headingLabel.leadingAnchor.constraint(equalTo: iconDisc.trailingAnchor, constant: 9),
            headingLabel.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 18),
            headingLabel.trailingAnchor.constraint(lessThanOrEqualTo: materialView.trailingAnchor, constant: -14),

            bodyLabel.leadingAnchor.constraint(equalTo: iconDisc.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 4),
            bodyLabel.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -14),

            dragSource.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 14),
            dragSource.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -14),
            dragSource.bottomAnchor.constraint(equalTo: materialView.bottomAnchor, constant: -12),
            dragSource.heightAnchor.constraint(equalToConstant: 40),
        ]

        if let trustNoteLabel {
            constraints.append(contentsOf: [
                trustNoteLabel.leadingAnchor.constraint(equalTo: bodyLabel.leadingAnchor),
                trustNoteLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4),
                trustNoteLabel.trailingAnchor.constraint(equalTo: bodyLabel.trailingAnchor),
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Default fallback covers both flows (toggle if the app is already
    /// listed, drag if not). Apps typically pass their own instruction
    /// tailored to the specific permission and product context.
    private func instructionText(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        override: String?
    ) -> String {
        override ?? "Turn on \(hostApp.displayName) in the list — drag it in from below if it's not there yet."
    }

    // MARK: - Whole-overlay drag source

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        chipView?.setHovering(true)
    }

    override func mouseExited(with event: NSEvent) {
        chipView?.setHovering(false)
    }

    override func mouseDown(with event: NSEvent) {
        guard let chipView else {
            return
        }

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setDataProvider(self, forTypes: [.fileURL])

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        // Preview shows the chip visual because it is what represents the
        // dragged file (the app bundle URL); the wider hit target is a
        // convenience so users don't have to aim for a small chip.
        let previewFrameInSelf = convert(chipView.bounds, from: chipView)
        draggingItem.setDraggingFrame(previewFrameInSelf, contents: chipView.draggingPreviewImage())

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    func pasteboard(
        _ pasteboard: NSPasteboard?,
        item: NSPasteboardItem,
        provideDataForType type: NSPasteboard.PasteboardType
    ) {
        guard type == .fileURL else {
            return
        }
        item.setData(bundleURLData, forType: .fileURL)
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        chipView?.setHiddenDuringDrag(true)
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        chipView?.setHiddenDuringDrag(false)
    }

    private static var glowBridgeKey: UInt8 = 0
}

/// Keeps a CAGradientLayer's frame in sync with its host NSView's bounds.
/// Constraint-based layout does not resize sublayers automatically, and
/// resizing the layer inside layout() would require subclassing the host
/// view — this coordinator observes bounds instead.
@MainActor
private final class KikiOverlayGlowLayoutBridge: NSObject {
    private weak var host: NSView?
    private weak var layer: CAGradientLayer?
    private var observation: NSKeyValueObservation?

    init(host: NSView, layer: CAGradientLayer) {
        self.host = host
        self.layer = layer
        super.init()
        host.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hostFrameDidChange(_:)),
            name: NSView.frameDidChangeNotification,
            object: host
        )
        sync()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc nonisolated private func hostFrameDidChange(_ notification: Notification) {
        Task { @MainActor in
            self.sync()
        }
    }

    private func sync() {
        guard let host, let layer else {
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = host.bounds
        CATransaction.commit()
    }
}
