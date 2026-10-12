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
    private let heightPolicy: KikiSettingsWindowHeightPolicy
    private let onFittedContentHeightChange: ((CGFloat) -> Void)?
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
        self.heightPolicy = .fixed
        self.onFittedContentHeightChange = nil
        self.content = content
    }

    init(
        selection: Binding<Tab>,
        tabs: [KikiSettingsTabSpec<Tab>],
        width: CGFloat,
        height: CGFloat,
        minimumWidth: CGFloat,
        minimumHeight: CGFloat,
        maximumWidth: CGFloat,
        maximumHeight: CGFloat,
        heightPolicy: KikiSettingsWindowHeightPolicy,
        onFittedContentHeightChange: ((CGFloat) -> Void)?,
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
        self.heightPolicy = heightPolicy
        self.onFittedContentHeightChange = onFittedContentHeightChange
        self.content = content
    }

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { tabSpec in
                tabContent(for: tabSpec)
                .tabItem {
                    Label(tabSpec.title, systemImage: tabSpec.systemImage)
                }
                .tag(tabSpec.tab)
            }
        }
        .onPreferenceChange(KikiSettingsFittingHeightPreferenceKey.self) { height in
            guard heightPolicy == .fitsContent, let height else {
                return
            }
            onFittedContentHeightChange?(height)
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

    @ViewBuilder
    private func tabContent(for tabSpec: KikiSettingsTabSpec<Tab>) -> some View {
        if heightPolicy == .fitsContent {
            KikiSettingsFittingTab(
                isSelected: selection == tabSpec.tab,
                minimumHeight: minimumHeight,
                maximumHeight: maximumHeight
            ) {
                content(tabSpec.tab)
            }
        } else {
            content(tabSpec.tab)
        }
    }
}

private struct KikiSettingsFittingHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() {
            value = next
        }
    }
}

/// Measures the existing tab view with an unspecified vertical proposal, then
/// places that same view within the configured bounds. This keeps Form's own
/// scrolling behavior when the pane is taller than the maximum.
private struct KikiSettingsFittingTab<Content: View>: View {
    let isSelected: Bool
    let minimumHeight: CGFloat
    let maximumHeight: CGFloat
    let content: Content

    init(
        isSelected: Bool,
        minimumHeight: CGFloat,
        maximumHeight: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.minimumHeight = minimumHeight
        self.maximumHeight = maximumHeight
        self.content = content()
    }

    var body: some View {
        KikiSettingsFittingTabLayout(
            minimumHeight: minimumHeight,
            maximumHeight: maximumHeight
        ) {
            content
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: KikiSettingsFittingHeightPreferenceKey.self,
                            value: isSelected ? proxy.size.height : nil
                        )
                    }
                }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct KikiSettingsFittingTabLayout: Layout {
    let minimumHeight: CGFloat
    let maximumHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        let fittingSize = subview.sizeThatFits(
            ProposedViewSize(width: proposal.width, height: nil)
        )
        return CGSize(
            width: proposal.width ?? fittingSize.width,
            height: clampedHeight(fittingSize.height)
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else {
            return
        }
        subview.place(
            at: bounds.origin,
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
        )
    }

    private func clampedHeight(_ height: CGFloat) -> CGFloat {
        guard height.isFinite else {
            return minimumHeight
        }
        return min(max(height, minimumHeight), maximumHeight)
    }
}
