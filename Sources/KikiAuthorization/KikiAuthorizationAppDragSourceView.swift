import AppKit
import Foundation

final class KikiAuthorizationAppDragSourceView: NSView, NSPasteboardItemDataProvider, NSDraggingSource {
    private let hostApp: KikiAuthorizationHostApp
    private let bundleURLData: Data
    private let rowView = NSView()
    private let iconBackgroundView = NSView()
    private let label = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "Drag to the list above")

    init(hostApp: KikiAuthorizationHostApp) {
        self.hostApp = hostApp
        self.bundleURLData = hostApp.bundleURL.dataRepresentation
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildView()
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setDataProvider(self, forTypes: [.fileURL])

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(rowView.frame, contents: draggingImage())

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
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

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        rowView.isHidden = true
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        rowView.isHidden = false
    }

    private func buildView() {
        wantsLayer = true

        rowView.translatesAutoresizingMaskIntoConstraints = false
        rowView.wantsLayer = true
        rowView.layer?.cornerRadius = 8
        rowView.layer?.borderWidth = 1
        addSubview(rowView)

        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.wantsLayer = true
        iconBackgroundView.layer?.cornerRadius = 6
        iconBackgroundView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.92).cgColor
        rowView.addSubview(iconBackgroundView)

        let iconView = NSImageView(image: hostApp.icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconBackgroundView.addSubview(iconView)

        label.stringValue = hostApp.displayName
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = NSColor.labelColor.withAlphaComponent(0.84)
        label.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(label)

        detailLabel.font = .systemFont(ofSize: 11.5)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(detailLabel)

        let dragIndicator = NSImageView()
        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        dragIndicator.image = NSImage(systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: "Drag upward")
        dragIndicator.symbolConfiguration = .init(pointSize: 16, weight: .medium)
        dragIndicator.contentTintColor = .controlAccentColor
        rowView.addSubview(dragIndicator)

        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowView.topAnchor.constraint(equalTo: topAnchor),
            rowView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconBackgroundView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 10),
            iconBackgroundView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 27),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 27),

            iconView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 11),
            label.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 7),
            label.trailingAnchor.constraint(lessThanOrEqualTo: dragIndicator.leadingAnchor, constant: -10),

            detailLabel.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: label.bottomAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: dragIndicator.leadingAnchor, constant: -10),

            dragIndicator.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -12),
            dragIndicator.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 20),
            dragIndicator.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    private func updateColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        if isDark {
            rowView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.07).cgColor
            rowView.layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
        } else {
            rowView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.68).cgColor
            rowView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.22).cgColor
        }
    }

    private func draggingImage() -> NSImage {
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
}
