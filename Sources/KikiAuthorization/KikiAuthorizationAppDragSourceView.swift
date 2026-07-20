import AppKit
import Foundation

/// The chip displayed at the bottom of the authorization overlay.
///
/// Purely a visual and hover-state surface — the drag session itself is
/// initiated by `KikiAuthorizationOverlayView`, whose whole area is a
/// drag source so users don't have to aim for the chip. This view exposes
/// `setHovering(_:)` and `draggingPreviewImage()` for the parent to drive.
final class KikiAuthorizationAppDragSourceView: NSView {
    private let hostApp: KikiAuthorizationHostApp
    private let tint: NSColor
    private let rowView = NSView()
    private let iconBackgroundView = NSView()
    private let label = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "Drag me into the list")
    private let dragIndicator = NSImageView()
    private var isHovering = false

    init(hostApp: KikiAuthorizationHostApp, tint: NSColor = .controlAccentColor) {
        self.hostApp = hostApp
        self.tint = tint
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildView()
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    func setHovering(_ hovering: Bool) {
        guard isHovering != hovering else {
            return
        }
        isHovering = hovering
        updateColors()
    }

    func setHiddenDuringDrag(_ hidden: Bool) {
        rowView.isHidden = hidden
    }

    func draggingPreviewImage() -> NSImage {
        layoutSubtreeIfNeeded()

        let bounds = rowView.bounds
        let image = NSImage(size: bounds.size)

        guard let representation = rowView.bitmapImageRepForCachingDisplay(in: bounds) else {
            return hostApp.icon
        }

        rowView.cacheDisplay(in: bounds, to: representation)
        image.addRepresentation(representation)
        return image
    }

    private func buildView() {
        wantsLayer = true

        rowView.translatesAutoresizingMaskIntoConstraints = false
        rowView.wantsLayer = true
        rowView.layer?.cornerRadius = 8
        // No border, no drop shadow: both were reading as dark grit against
        // the overlay's material. The chip announces itself through fill
        // contrast alone; hover deepens the fill so the affordance still
        // registers.
        rowView.layer?.borderWidth = 0
        rowView.layer?.masksToBounds = true
        addSubview(rowView)

        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.wantsLayer = true
        iconBackgroundView.layer?.cornerRadius = 5
        // A whisper of white behind the app icon makes small icons pop off
        // the material — analogous to Apple's rounded-corner icon tiles in
        // Notification Center and the Menu Bar's Battery/Wi-Fi popovers.
        iconBackgroundView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.85).cgColor
        rowView.addSubview(iconBackgroundView)

        let iconView = NSImageView(image: hostApp.icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconBackgroundView.addSubview(iconView)

        label.stringValue = hostApp.displayName
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(label)

        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(detailLabel)

        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        // hand.point.up.left signals "drag with pointer" instead of
        // arrow.up.circle.fill, which read as an "upload" button and
        // invited clicks on a non-interactive glyph.
        dragIndicator.image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "Drag upward")
        dragIndicator.symbolConfiguration = .init(pointSize: 15, weight: .medium)
        dragIndicator.contentTintColor = .secondaryLabelColor
        rowView.addSubview(dragIndicator)

        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowView.topAnchor.constraint(equalTo: topAnchor),
            rowView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconBackgroundView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 8),
            iconBackgroundView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 24),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 24),

            iconView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 9),
            label.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -8),

            detailLabel.trailingAnchor.constraint(equalTo: dragIndicator.leadingAnchor, constant: -6),
            detailLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),

            dragIndicator.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -10),
            dragIndicator.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 18),
            dragIndicator.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    private func updateColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Idle: a whisper of white so the chip reads as an inset panel on
        // the material; hover bumps opacity so the affordance registers.
        // No border, no shadow — the whole popover already has AppKit's
        // drop shadow via window.hasShadow, so extra depth here would
        // stack into visible grit.
        let idleAlpha: CGFloat = isDark ? 0.06 : 0.5
        let hoverAlpha: CGFloat = isDark ? 0.14 : 0.75

        rowView.layer?.backgroundColor = NSColor.white
            .withAlphaComponent(isHovering ? hoverAlpha : idleAlpha)
            .cgColor

        dragIndicator.contentTintColor = isHovering ? tint : .secondaryLabelColor
        detailLabel.textColor = isHovering ? .labelColor : .secondaryLabelColor
    }
}
