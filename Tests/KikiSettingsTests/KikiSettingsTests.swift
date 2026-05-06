import KikiSettings
import Testing

struct KikiSettingsTests {
    @MainActor
    @Test("Navigation model stores selected tab")
    func navigationModelStoresSelectedTab() {
        enum Tab: Hashable {
            case general
            case about
        }

        let model = KikiSettingsNavigationModel<Tab>(selectedTab: .general)
        #expect(model.selectedTab == .general)

        model.selectedTab = .about
        #expect(model.selectedTab == .about)
    }
}
