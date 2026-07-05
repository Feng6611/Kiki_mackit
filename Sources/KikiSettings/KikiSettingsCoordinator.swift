import AppKit
import SwiftUI

@MainActor
public final class KikiSettingsCoordinator<Tab: Hashable> {
    public let navigation: KikiSettingsNavigationModel<Tab>
    public let opener: KikiSettingsOpener
    public let windowController: KikiSettingsWindowController?
    public let tabs: [KikiSettingsTabSpec<Tab>]

    public init(
        tabs: [KikiSettingsTabSpec<Tab>],
        initialTab: Tab,
        windowController: KikiSettingsWindowController? = nil
    ) {
        self.tabs = tabs
        self.navigation = KikiSettingsNavigationModel(selectedTab: initialTab)
        self.windowController = windowController
        self.opener = KikiSettingsOpener(windowController: windowController)
    }

    public var isVisible: Bool {
        windowController?.isVisible ?? false
    }

    public func select(_ tab: Tab) {
        navigation.selectedTab = tab
    }

    public func open(tab: Tab? = nil, isMenuBarApp: Bool = true) {
        if let tab {
            navigation.selectedTab = tab
        }
        if isMenuBarApp {
            opener.openForMenuBarApp()
        } else {
            opener.open()
        }
    }

    public func close() {
        windowController?.close()
    }

    public func prepare() {
        opener.prepare()
    }
}

public struct KikiSettingsCoordinatorView<Tab: Hashable, Content: View>: View {
    @ObservedObject private var navigation: KikiSettingsNavigationModel<Tab>
    private let tabs: [KikiSettingsTabSpec<Tab>]
    private let width: CGFloat
    private let height: CGFloat
    private let windowController: KikiSettingsWindowController?
    private let content: (Tab) -> Content

    public init(
        coordinator: KikiSettingsCoordinator<Tab>,
        width: CGFloat = KikiSettingsDefaults.windowWidth,
        height: CGFloat = KikiSettingsDefaults.windowHeight,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self.navigation = coordinator.navigation
        self.tabs = coordinator.tabs
        self.width = width
        self.height = height
        self.windowController = coordinator.windowController
        self.content = content
    }

    public var body: some View {
        KikiSettingsShell(
            selection: $navigation.selectedTab,
            tabs: tabs,
            width: width,
            height: height,
            content: content
        )
        .kikiSettingsWindow(windowController)
    }
}

@MainActor
private final class KikiSettingsWindowRegistrationView: NSView {
    var onWindowAvailable: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else {
            return
        }
        onWindowAvailable?(window)
    }
}

private struct KikiSettingsWindowRegistration: NSViewRepresentable {
    let controller: KikiSettingsWindowController?

    func makeNSView(context: Context) -> KikiSettingsWindowRegistrationView {
        let view = KikiSettingsWindowRegistrationView()
        updateRegistration(for: view)
        return view
    }

    func updateNSView(_ nsView: KikiSettingsWindowRegistrationView, context: Context) {
        updateRegistration(for: nsView)
    }

    private func updateRegistration(for view: KikiSettingsWindowRegistrationView) {
        view.onWindowAvailable = { [weak controller] window in
            controller?.register(window: window)
        }
        if let window = view.window {
            controller?.register(window: window)
        }
    }
}

public extension View {
    /// Registers the native SwiftUI Settings window with Kiki so frame
    /// restoration, visibility, and imperative close operate on one exact
    /// window instead of scanning unrelated application windows.
    func kikiSettingsWindow(_ controller: KikiSettingsWindowController?) -> some View {
        background {
            KikiSettingsWindowRegistration(controller: controller)
                .frame(width: 0, height: 0)
        }
    }
}
