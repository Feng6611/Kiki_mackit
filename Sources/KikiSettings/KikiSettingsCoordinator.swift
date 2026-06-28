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

    public func prepare() {
        opener.prepare()
    }
}

public struct KikiSettingsCoordinatorView<Tab: Hashable, Content: View>: View {
    @ObservedObject private var navigation: KikiSettingsNavigationModel<Tab>
    private let tabs: [KikiSettingsTabSpec<Tab>]
    private let width: CGFloat
    private let height: CGFloat
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
    }
}
