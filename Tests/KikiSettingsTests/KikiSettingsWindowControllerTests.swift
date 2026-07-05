import Foundation
@testable import KikiSettings
import XCTest

@MainActor
final class KikiSettingsWindowControllerTests: XCTestCase {
    func testRegisteredWindowOwnsConfigurationVisibilityAndClose() {
        let controller = KikiSettingsWindowController(
            frameAutosaveName: "KikiSettingsTests.Window",
            minimumContentSize: CGSize(width: 420, height: 320)
        )
        let window = FakeSettingsWindow()

        controller.register(managedWindow: window)

        XCTAssertEqual(window.configuredAutosaveName, "KikiSettingsTests.Window")
        XCTAssertEqual(window.configuredMinimumSize, CGSize(width: 420, height: 320))
        XCTAssertTrue(controller.isVisible)

        controller.close()
        XCTAssertTrue(window.didClose)
        XCTAssertFalse(controller.isVisible)
    }
}

@MainActor
private final class FakeSettingsWindow: KikiSettingsWindowManaging {
    var isVisible = true
    private(set) var configuredAutosaveName: String?
    private(set) var configuredMinimumSize: CGSize?
    private(set) var didClose = false

    func configure(
        frameAutosaveName: String,
        minimumContentSize: CGSize
    ) {
        configuredAutosaveName = frameAutosaveName
        configuredMinimumSize = minimumContentSize
    }

    func close() {
        didClose = true
        isVisible = false
    }
}
