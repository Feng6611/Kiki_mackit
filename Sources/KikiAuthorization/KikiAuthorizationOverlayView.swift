import AppKit
import Foundation

@MainActor
final class KikiAuthorizationOverlayView: NSView {
    private let onDismiss: () -> Void

    init(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        super.init(frame: NSRect(x: 0, y: 0, width: 520, height: 112))
        translatesAutoresizingMaskIntoConstraints = false
        buildView(hostApp: hostApp, panel: panel, instruction: instruction)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?
    ) {
        let materialView = NSVisualEffectView()
        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.material = .popover
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.wantsLayer = true
        materialView.layer?.cornerRadius = 18
        materialView.layer?.masksToBounds = true
        materialView.layer?.borderWidth = 0.5
        materialView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.18).cgColor
        addSubview(materialView)

        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.76).cgColor
        materialView.addSubview(tintView)

        let backButton = NSButton()
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isBordered = false
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back")
        backButton.contentTintColor = .secondaryLabelColor
        backButton.target = self
        backButton.action = #selector(dismissPressed)
        materialView.addSubview(backButton)

        let arrowView = NSImageView()
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        arrowView.symbolConfiguration = .init(pointSize: 27, weight: .bold)
        arrowView.contentTintColor = .controlAccentColor
        materialView.addSubview(arrowView)

        let titleLabel = NSTextField(labelWithString: instructionText(
            hostApp: hostApp,
            panel: panel,
            override: instruction
        ))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = NSColor.labelColor.withAlphaComponent(0.84)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        materialView.addSubview(titleLabel)

        let dragSource = KikiAuthorizationAppDragSourceView(hostApp: hostApp)
        materialView.addSubview(dragSource)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 520),
            heightAnchor.constraint(equalToConstant: 112),

            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: materialView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: materialView.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: materialView.bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 18),
            backButton.bottomAnchor.constraint(equalTo: materialView.bottomAnchor, constant: -18),
            backButton.widthAnchor.constraint(equalToConstant: 28),
            backButton.heightAnchor.constraint(equalToConstant: 28),

            arrowView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 34),
            arrowView.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 12),
            arrowView.widthAnchor.constraint(equalToConstant: 28),
            arrowView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: arrowView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -22),

            dragSource.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 62),
            dragSource.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -22),
            dragSource.bottomAnchor.constraint(equalTo: materialView.bottomAnchor, constant: -16),
            dragSource.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func instructionText(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        override: String?
    ) -> String {
        override ?? "Drag \(hostApp.displayName) to the list above to allow \(panel.title)"
    }

    @objc private func dismissPressed() {
        onDismiss()
    }
}
