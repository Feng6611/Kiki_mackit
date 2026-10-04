import AppKit
import KikiCore
import SwiftUI

public struct KikiWindowButtonVisibility: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let close = KikiWindowButtonVisibility(rawValue: 1 << 0)
    public static let miniaturize = KikiWindowButtonVisibility(rawValue: 1 << 1)
    public static let zoom = KikiWindowButtonVisibility(rawValue: 1 << 2)
    public static let all: KikiWindowButtonVisibility = [.close, .miniaturize, .zoom]
}

public struct KikiWindowConfiguration {
    public var title: String
    public var size: CGSize
    public var minimumSize: CGSize?
    public var styleMask: NSWindow.StyleMask
    public var frameAutosaveName: String?
    public var titlebarAppearsTransparent: Bool
    public var titleVisibility: NSWindow.TitleVisibility
    public var isMovableByWindowBackground: Bool
    public var backgroundColor: NSColor
    public var contentCornerRadius: CGFloat?
    public var isReleasedWhenClosed: Bool
    public var hiddenButtons: KikiWindowButtonVisibility
    public var centersOnShow: Bool
    public var activatesAppOnShow: Bool

    public init(
        title: String,
        size: CGSize,
        minimumSize: CGSize? = nil,
        styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable],
        frameAutosaveName: String? = nil,
        titlebarAppearsTransparent: Bool = false,
        titleVisibility: NSWindow.TitleVisibility = .visible,
        isMovableByWindowBackground: Bool = false,
        backgroundColor: NSColor = .windowBackgroundColor,
        contentCornerRadius: CGFloat? = nil,
        isReleasedWhenClosed: Bool = false,
        hiddenButtons: KikiWindowButtonVisibility = [],
        centersOnShow: Bool = true,
        activatesAppOnShow: Bool = true
    ) {
        self.title = title
        self.size = size
        self.minimumSize = minimumSize
        self.styleMask = styleMask
        self.frameAutosaveName = frameAutosaveName
        self.titlebarAppearsTransparent = titlebarAppearsTransparent
        self.titleVisibility = titleVisibility
        self.isMovableByWindowBackground = isMovableByWindowBackground
        self.backgroundColor = backgroundColor
        self.contentCornerRadius = contentCornerRadius
        self.isReleasedWhenClosed = isReleasedWhenClosed
        self.hiddenButtons = hiddenButtons
        self.centersOnShow = centersOnShow
        self.activatesAppOnShow = activatesAppOnShow
    }

    public static func utility(
        title: String,
        size: CGSize,
        minimumSize: CGSize? = nil,
        frameAutosaveName: String? = nil
    ) -> KikiWindowConfiguration {
        KikiWindowConfiguration(
            title: title,
            size: size,
            minimumSize: minimumSize,
            styleMask: [.titled, .closable, .miniaturizable],
            frameAutosaveName: frameAutosaveName
        )
    }

    public static func transparentUtility(
        title: String,
        size: CGSize,
        minimumSize: CGSize? = nil,
        frameAutosaveName: String? = nil,
        hiddenButtons: KikiWindowButtonVisibility = []
    ) -> KikiWindowConfiguration {
        KikiWindowConfiguration(
            title: title,
            size: size,
            minimumSize: minimumSize,
            // Borderless removes the otherwise detached transparent title-bar
            // shadow. The content remains draggable through
            // `isMovableByWindowBackground` below.
            styleMask: [.borderless],
            frameAutosaveName: frameAutosaveName,
            titlebarAppearsTransparent: true,
            titleVisibility: .hidden,
            isMovableByWindowBackground: true,
            backgroundColor: .clear,
            contentCornerRadius: 20,
            hiddenButtons: hiddenButtons
        )
    }
}

public struct KikiTransparentWindowBackground: NSViewRepresentable {
    private let titlebarAppearsTransparent: Bool
    private let clearsBackground: Bool
    private let isMovableByWindowBackground: Bool
    private let frameAutosaveName: String?

    public init(
        titlebarAppearsTransparent: Bool = true,
        clearsBackground: Bool = true,
        isMovableByWindowBackground: Bool = false,
        frameAutosaveName: String? = nil
    ) {
        self.titlebarAppearsTransparent = titlebarAppearsTransparent
        self.clearsBackground = clearsBackground
        self.isMovableByWindowBackground = isMovableByWindowBackground
        self.frameAutosaveName = frameAutosaveName
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            apply(to: view.window)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        apply(to: nsView.window)
    }

    private func apply(to window: NSWindow?) {
        guard let window else {
            return
        }

        if clearsBackground {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        }

        window.titlebarAppearsTransparent = titlebarAppearsTransparent
        window.isMovableByWindowBackground = isMovableByWindowBackground

        if let frameAutosaveName {
            window.setFrameAutosaveName(NSWindow.FrameAutosaveName(frameAutosaveName))
        }
    }
}

public extension View {
    func kikiTransparentWindowBackground(
        titlebarAppearsTransparent: Bool = true,
        clearsBackground: Bool = true,
        isMovableByWindowBackground: Bool = false,
        frameAutosaveName: String? = nil
    ) -> some View {
        background {
            KikiTransparentWindowBackground(
                titlebarAppearsTransparent: titlebarAppearsTransparent,
                clearsBackground: clearsBackground,
                isMovableByWindowBackground: isMovableByWindowBackground,
                frameAutosaveName: frameAutosaveName
            )
        }
    }
}

/// A desktop-sampled material background for a SwiftUI `Window` or
/// `WindowGroup`. Unlike a regular SwiftUI `Material`, this bridge clears the
/// host `NSWindow` and asks AppKit to blend the visual effect behind it.
public struct KikiDesktopGlassWindowBackground: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let tint: NSColor
    private let tintOpacity: CGFloat
    private let isMovableByWindowBackground: Bool
    private let extendsIntoTitlebar: Bool

    public init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        tint: Color = .clear,
        tintOpacity: Double = 0,
        isMovableByWindowBackground: Bool = false,
        extendsIntoTitlebar: Bool = true
    ) {
        self.material = material
        self.tint = NSColor(tint)
        self.tintOpacity = max(0, min(tintOpacity, 1))
        self.isMovableByWindowBackground = isMovableByWindowBackground
        self.extendsIntoTitlebar = extendsIntoTitlebar
    }

    public func makeNSView(context: Context) -> KikiDesktopGlassView {
        KikiDesktopGlassView(
            material: material,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateNSView(_ nsView: KikiDesktopGlassView, context: Context) {
        nsView.update(material: material, tint: tint, tintOpacity: tintOpacity)
        applyWindowTransparency(to: nsView.window)
    }

    private func applyWindowTransparency(to window: NSWindow?) {
        guard let window else {
            return
        }

        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = isMovableByWindowBackground
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        if extendsIntoTitlebar {
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        }
    }
}

public extension View {
    /// Installs a desktop-sampled AppKit material behind this view and clears
    /// the host window background. Use it for the outermost app workspace,
    /// not for cards or controls inside that workspace.
    func kikiDesktopGlassWindowBackground(
        material: NSVisualEffectView.Material = .underWindowBackground,
        tint: Color = .clear,
        tintOpacity: Double = 0,
        isMovableByWindowBackground: Bool = false,
        extendsIntoTitlebar: Bool = true
    ) -> some View {
        background {
            KikiDesktopGlassWindowBackground(
                material: material,
                tint: tint,
                tintOpacity: tintOpacity,
                isMovableByWindowBackground: isMovableByWindowBackground,
                extendsIntoTitlebar: extendsIntoTitlebar
            )
        }
    }
}

public final class KikiDesktopGlassView: NSVisualEffectView {
    private let tintView = NSView()

    init(material: NSVisualEffectView.Material, tint: NSColor, tintOpacity: CGFloat) {
        super.init(frame: .zero)
        blendingMode = .behindWindow
        state = .active
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        addSubview(tintView)
        NSLayoutConstraint.activate([
            tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintView.topAnchor.constraint(equalTo: topAnchor),
            tintView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        update(material: material, tint: tint, tintOpacity: tintOpacity)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(material: NSVisualEffectView.Material, tint: NSColor, tintOpacity: CGFloat) {
        self.material = material
        tintView.layer?.backgroundColor = tint.withAlphaComponent(tintOpacity).cgColor
    }
}

private final class KikiWindowContentView: NSView {
    private let cornerRadius: CGFloat?

    init(cornerRadius: CGFloat?) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)

        if cornerRadius != nil {
            wantsLayer = true
            applyCornerRadius()
        }
    }

    required init?(coder: NSCoder) {
        cornerRadius = nil
        super.init(coder: coder)
    }

    override func layout() {
        super.layout()
        // AppKit can rebuild the backing layer when a transparent utility
        // window becomes the parent of a sheet. Reapply the clip after that
        // transition so the parent onboarding surface cannot expose square
        // corners around the sheet.
        applyCornerRadius()
    }

    private func applyCornerRadius() {
        guard let cornerRadius else {
            return
        }

        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
    }
}

@MainActor
public final class KikiSingleWindowController<Content: View>: NSObject, NSWindowDelegate {
    private let configuration: KikiWindowConfiguration
    private let content: () -> Content
    private let onClose: (() -> Void)?

    /// Escape hatch for product window behavior the controller does not model
    /// (e.g. miniaturize-driven onboarding sessions). Nil until first `show()`.
    public private(set) var window: NSWindow?

    public init(
        configuration: KikiWindowConfiguration,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.configuration = configuration
        self.content = content
        self.onClose = onClose
    }

    public var isVisible: Bool {
        window?.isVisible == true
    }

    public func show() {
        if let window {
            present(window, centering: configuration.centersOnShow && configuration.frameAutosaveName == nil)
            return
        }

        let hadSavedFrame = Self.hasSavedFrame(named: configuration.frameAutosaveName)
        let window = makeWindow()
        self.window = window
        present(window, centering: configuration.centersOnShow && !hadSavedFrame)
    }

    /// `setFrameAutosaveName` silently restores a stored frame, so a first
    /// launch (nothing stored, or an empty name) must be centered explicitly.
    private static func hasSavedFrame(named name: String?) -> Bool {
        guard let name, !name.isEmpty else { return false }
        return UserDefaults.standard.string(forKey: "NSWindow Frame \(name)") != nil
    }

    public func close() {
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let hostingView = NSHostingView(rootView: content())
        let contentView = KikiWindowContentView(
            cornerRadius: configuration.contentCornerRadius
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: configuration.size),
            styleMask: configuration.styleMask,
            backing: .buffered,
            defer: false
        )
        window.contentView = contentView
        configure(window)
        return window
    }

    private func configure(_ window: NSWindow) {
        window.title = configuration.title
        window.delegate = self
        window.styleMask = configuration.styleMask
        window.titlebarAppearsTransparent = configuration.titlebarAppearsTransparent
        window.titleVisibility = configuration.titleVisibility
        window.isMovableByWindowBackground = configuration.isMovableByWindowBackground
        window.backgroundColor = configuration.backgroundColor
        window.isOpaque = configuration.backgroundColor.alphaComponent >= 1
        window.hasShadow = true
        if let cornerRadius = configuration.contentCornerRadius {
            applyWindowSurface(to: window, cornerRadius: cornerRadius)
        }
        window.isReleasedWhenClosed = configuration.isReleasedWhenClosed
        window.setContentSize(configuration.size)

        if let minimumSize = configuration.minimumSize {
            window.contentMinSize = minimumSize
        }

        if let frameAutosaveName = configuration.frameAutosaveName {
            window.setFrameAutosaveName(NSWindow.FrameAutosaveName(frameAutosaveName))
        }

        setButton(.closeButton, hidden: configuration.hiddenButtons.contains(.close), in: window)
        setButton(.miniaturizeButton, hidden: configuration.hiddenButtons.contains(.miniaturize), in: window)
        setButton(.zoomButton, hidden: configuration.hiddenButtons.contains(.zoom), in: window)
    }

    private func applyWindowSurface(to window: NSWindow, cornerRadius: CGFloat) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = cornerRadius
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true
    }

    private func repairWindowSurface() {
        guard let window, let cornerRadius = configuration.contentCornerRadius else {
            return
        }

        applyWindowSurface(to: window, cornerRadius: cornerRadius)
    }

    private func setButton(_ button: NSWindow.ButtonType, hidden: Bool, in window: NSWindow) {
        window.standardWindowButton(button)?.isHidden = hidden
    }

    private func present(_ window: NSWindow, centering: Bool) {
        if centering {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)

        if configuration.activatesAppOnShow {
            KikiAppActivation.activate()
        }
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
        onClose?()
    }

    public func windowDidBecomeKey(_ notification: Notification) {
        repairWindowSurface()
    }

    public func windowDidResignKey(_ notification: Notification) {
        repairWindowSurface()
    }

    public func windowDidResize(_ notification: Notification) {
        repairWindowSurface()
    }

    public func windowWillBeginSheet(_ notification: Notification) {
        repairWindowSurface()
    }

    public func windowDidEndSheet(_ notification: Notification) {
        repairWindowSurface()
    }
}
