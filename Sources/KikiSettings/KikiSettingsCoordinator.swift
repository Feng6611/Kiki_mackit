import AppKit
import Combine
import SwiftUI

@MainActor
public final class KikiSettingsCoordinator<Tab: Hashable>: ObservableObject {
    public let navigation: KikiSettingsNavigationModel<Tab>
    public let opener: KikiSettingsOpener
    public let windowController: KikiSettingsWindowController?
    @Published public private(set) var tabs: [KikiSettingsTabSpec<Tab>]

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

    /// Replaces caller-owned labels while preserving the selected tab and the
    /// native Settings window. Useful when the host changes its live locale.
    public func updateTabs(_ tabs: [KikiSettingsTabSpec<Tab>]) {
        self.tabs = tabs
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
    @ObservedObject private var coordinator: KikiSettingsCoordinator<Tab>
    private let layout: KikiSettingsWindowLayout
    private let windowController: KikiSettingsWindowController?
    private let content: (Tab) -> Content

    public init(
        coordinator: KikiSettingsCoordinator<Tab>,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        minimumWidth: CGFloat? = nil,
        minimumHeight: CGFloat? = nil,
        maximumWidth: CGFloat?,
        maximumHeight: CGFloat?,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self.navigation = coordinator.navigation
        self.coordinator = coordinator
        let base = coordinator.windowController?.layout ?? KikiSettingsWindowLayout()
        self.layout = KikiSettingsWindowLayout(
            ideal: CGSize(width: width ?? base.ideal.width, height: height ?? base.ideal.height),
            minimum: CGSize(width: minimumWidth ?? base.minimum.width, height: minimumHeight ?? base.minimum.height),
            maximum: CGSize(width: maximumWidth ?? base.maximum.width, height: maximumHeight ?? base.maximum.height)
        )
        self.windowController = coordinator.windowController
        self.content = content
    }

    public init(coordinator: KikiSettingsCoordinator<Tab>, width: CGFloat = KikiSettingsDefaults.windowWidth, height: CGFloat = KikiSettingsDefaults.windowHeight,
                minimumWidth: CGFloat = KikiSettingsDefaults.minimumWindowWidth, minimumHeight: CGFloat = KikiSettingsDefaults.minimumWindowHeight,
                @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(coordinator: coordinator, width: width == KikiSettingsDefaults.windowWidth ? nil : width,
                  height: height == KikiSettingsDefaults.windowHeight ? nil : height,
                  minimumWidth: minimumWidth == KikiSettingsDefaults.minimumWindowWidth ? nil : minimumWidth,
                  minimumHeight: minimumHeight == KikiSettingsDefaults.minimumWindowHeight ? nil : minimumHeight,
                  maximumWidth: nil, maximumHeight: nil, content: content)
    }

    public var body: some View {
        KikiSettingsShell(
            selection: $navigation.selectedTab,
            tabs: coordinator.tabs,
            width: layout.ideal.width,
            height: layout.ideal.height,
            minimumWidth: layout.minimum.width,
            minimumHeight: layout.minimum.height,
            maximumWidth: layout.maximum.width,
            maximumHeight: layout.maximum.height,
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
