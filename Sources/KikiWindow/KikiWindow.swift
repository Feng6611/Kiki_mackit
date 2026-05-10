import AppKit
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
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            frameAutosaveName: frameAutosaveName,
            titlebarAppearsTransparent: true,
            titleVisibility: .hidden,
            isMovableByWindowBackground: true,
            backgroundColor: .clear,
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

@MainActor
public final class KikiSingleWindowController<Content: View>: NSObject, NSWindowDelegate {
    private let configuration: KikiWindowConfiguration
    private let content: () -> Content
    private let onClose: (() -> Void)?
    private var window: NSWindow?

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
            present(window)
            return
        }

        let window = makeWindow()
        self.window = window
        present(window)
    }

    public func close() {
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let hostingController = NSHostingController(rootView: content())
        let window = NSWindow(contentViewController: hostingController)
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

    private func setButton(_ button: NSWindow.ButtonType, hidden: Bool, in window: NSWindow) {
        window.standardWindowButton(button)?.isHidden = hidden
    }

    private func present(_ window: NSWindow) {
        if configuration.centersOnShow {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)

        if configuration.activatesAppOnShow {
            NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
        onClose?()
    }
}
