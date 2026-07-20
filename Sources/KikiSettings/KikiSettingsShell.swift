import SwiftUI

public enum KikiSettingsDefaults {
    /// Ideal Settings content width. Sized for menu-bar utility Settings —
    /// wider than SwiftUI's default `Settings {}` scene, narrower than the
    /// old 540 that left every row of a sparse pane looking half-empty.
    /// Apps with dense Settings content can pass explicit larger values.
    public static let windowWidth: CGFloat = 460
    public static let windowHeight: CGFloat = 520
    /// Lets the user drag the window narrower than ideal when their content
    /// fits. Kept above SwiftUI Form(.grouped)'s comfortable reading width.
    public static let minimumWindowWidth: CGFloat = 420
    public static let minimumWindowHeight: CGFloat = 320
    /// Caps the width so a legacy autosave frame or an aggressive drag
    /// doesn't leave narrow settings looking stranded in whitespace.
    public static let maximumWindowWidth: CGFloat = 560
    public static let maximumWindowHeight: CGFloat = 720
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
