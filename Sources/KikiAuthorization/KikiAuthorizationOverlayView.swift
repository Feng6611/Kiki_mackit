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
        super.init(frame: NSRect(x: 0, y: 0, width: 440, height: 138))
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

        let closeButton = NSButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")
        closeButton.symbolConfiguration = .init(pointSize: 13, weight: .semibold)
        closeButton.contentTintColor = .tertiaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(dismissPressed)
        materialView.addSubview(closeButton)

        let symbolBackground = NSView()
        symbolBackground.translatesAutoresizingMaskIntoConstraints = false
        symbolBackground.wantsLayer = true
        symbolBackground.layer?.cornerRadius = 9
        symbolBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.14).cgColor
        materialView.addSubview(symbolBackground)

        let symbolView = NSImageView()
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.image = NSImage(systemSymbolName: panel.systemImage, accessibilityDescription: panel.title)
        symbolView.symbolConfiguration = .init(pointSize: 17, weight: .medium)
        symbolView.contentTintColor = .controlAccentColor
        symbolBackground.addSubview(symbolView)

        let headingLabel = NSTextField(labelWithString: "Allow \(panel.title)")
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headingLabel.textColor = .labelColor
        materialView.addSubview(headingLabel)

        let titleLabel = NSTextField(labelWithString: instructionText(
            hostApp: hostApp,
            panel: panel,
            override: instruction
        ))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12.5, weight: .regular)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 2
        materialView.addSubview(titleLabel)

        let dragSource = KikiAuthorizationAppDragSourceView(hostApp: hostApp)
        materialView.addSubview(dragSource)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 440),
            heightAnchor.constraint(equalToConstant: 138),

            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),

            closeButton.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -10),
            closeButton.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),

            symbolBackground.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 16),
            symbolBackground.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 15),
            symbolBackground.widthAnchor.constraint(equalToConstant: 34),
            symbolBackground.heightAnchor.constraint(equalToConstant: 34),

            symbolView.centerXAnchor.constraint(equalTo: symbolBackground.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: symbolBackground.centerYAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: 20),
            symbolView.heightAnchor.constraint(equalToConstant: 20),

            headingLabel.leadingAnchor.constraint(equalTo: symbolBackground.trailingAnchor, constant: 11),
            headingLabel.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 14),
            headingLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -8),

            titleLabel.leadingAnchor.constraint(equalTo: headingLabel.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -34),

            dragSource.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 16),
            dragSource.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -16),
            dragSource.bottomAnchor.constraint(equalTo: materialView.bottomAnchor, constant: -14),
            dragSource.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func instructionText(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        override: String?
    ) -> String {
        override ?? "Drag the app below into the list in System Settings, then turn it on."
    }

    @objc private func dismissPressed() {
        onDismiss()
    }
}
