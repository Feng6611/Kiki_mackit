import SwiftUI

public enum KikiSettingsDefaults {
    public static let windowWidth: CGFloat = 540
    public static let windowHeight: CGFloat = 560
    public static let minimumWindowWidth: CGFloat = 540
    public static let minimumWindowHeight: CGFloat = 560
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
    private let content: (Tab) -> Content

    public init(
        selection: Binding<Tab>,
        tabs: [KikiSettingsTabSpec<Tab>],
        width: CGFloat = KikiSettingsDefaults.windowWidth,
        height: CGFloat = KikiSettingsDefaults.windowHeight,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.width = width
        self.height = height
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
        .frame(width: width, height: height)
    }
}
