import SwiftUI

public enum KikiSettingsDefaults {
    /// Settings width is fixed. Menu-bar utility Settings look uniform
    /// across apps when they don't drift with intrinsic content width, so
    /// min == ideal == max. Apps with genuinely wider content pass their
    /// own width to `KikiSettingsShell` / `KikiSettingsWindowController`.
    public static let windowWidth: CGFloat = 500
    public static let minimumWindowWidth: CGFloat = 500
    public static let maximumWindowWidth: CGFloat = 500

    /// Ideal height is sized for the busiest expected tab (Cat Lock's Lock
    /// pane, ~615pt). Fresh windows open at ideal; users who explicitly
    /// resize down to `minimum` get their frame respected on next launch.
    /// Content taller than `maximum` scrolls inside the pane.
    public static let windowHeight: CGFloat = 620
    public static let minimumWindowHeight: CGFloat = 480
    public static let maximumWindowHeight: CGFloat = 780
}

public struct KikiSettingsTabSpec<Tab: Hashable>: Identifiable {
    public let tab: Tab
    public let title: String
    public let systemImage: String

    public var id: Tab { tab }

    public init(_ tab: Tab, title: String, systemImage: String) {
        self.tab = tab
        self.title = title
        self.systemImage = systemImage
    }
}

@MainActor
public final class KikiSettingsNavigationModel<Tab: Hashable>: ObservableObject {
    @Published public var selectedTab: Tab

    public init(selectedTab: Tab) {
        self.selectedTab = selectedTab
    }
}

public struct KikiSettingsShell<Tab: Hashable, Content: View>: View {
    @Binding private var selection: Tab
    private let tabs: [KikiSettingsTabSpec<Tab>]
    private let width: CGFloat
    private let height: CGFloat
    private let minimumWidth: CGFloat
    private let minimumHeight: CGFloat
    private let maximumWidth: CGFloat
    private let maximumHeight: CGFloat
    private let content: (Tab) -> Content

    public init(
        selection: Binding<Tab>,
        tabs: [KikiSettingsTabSpec<Tab>],
        width: CGFloat = KikiSettingsDefaults.windowWidth,
        height: CGFloat = KikiSettingsDefaults.windowHeight,
        minimumWidth: CGFloat = KikiSettingsDefaults.minimumWindowWidth,
        minimumHeight: CGFloat = KikiSettingsDefaults.minimumWindowHeight,
        maximumWidth: CGFloat = KikiSettingsDefaults.maximumWindowWidth,
        maximumHeight: CGFloat = KikiSettingsDefaults.maximumWindowHeight,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.width = width
        self.height = height
        self.minimumWidth = minimumWidth
        self.minimumHeight = minimumHeight
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
        self.content = content
    }

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { tabSpec in
                content(tabSpec.tab)
                .tabItem {
                    Label(tabSpec.title, systemImage: tabSpec.systemImage)
                }
                .tag(tabSpec.tab)
            }
        }
        .frame(
            minWidth: minimumWidth,
            idealWidth: width,
            maxWidth: maximumWidth,
            minHeight: minimumHeight,
            idealHeight: height,
            maxHeight: maximumHeight
        )
    }
}
