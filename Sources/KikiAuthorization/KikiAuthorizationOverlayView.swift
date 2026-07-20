import AppKit
import Foundation

@MainActor
final class KikiAuthorizationOverlayView: NSView {
    private let onDismiss: () -> Void

    init(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?,
        trustNote: String?,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        super.init(frame: NSRect(x: 0, y: 0, width: 440, height: 138))
        autoresizingMask = [.width, .height]
        buildView(hostApp: hostApp, panel: panel, instruction: instruction, trustNote: trustNote)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView(
        hostApp: KikiAuthorizationHostApp,
        panel: KikiAuthorizationPanel,
        instruction: String?,
        trustNote: String?
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

        let dragSource = KikiAuthorizationAppDragSourceView(hostApp: hostApp)
        materialView.addSubview(dragSource)

        var constraints: [NSLayoutConstraint] = [
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
        ]

        if let trustNoteLabel {
            constraints.append(contentsOf: [
                trustNoteLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                trustNoteLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                trustNoteLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
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

    @objc private func dismissPressed() {
        onDismiss()
    }
}
