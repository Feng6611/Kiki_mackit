import Foundation
@testable import KikiSettings
import XCTest

@MainActor
final class KikiSettingsWindowControllerTests: XCTestCase {
    func testLegacyWindowTitleInitializerPreservesSourceCompatibility() {
        let controller = KikiSettingsWindowController(
            frameAutosaveName: "KikiSettingsTests.LegacyWindow",
            minimumContentSize: CGSize(width: 440, height: 330),
            windowTitle: "Settings"
        )
        let window = FakeSettingsWindow()

        controller.register(managedWindow: window)

        XCTAssertEqual(window.configuredAutosaveName, "KikiSettingsTests.LegacyWindow")
        XCTAssertEqual(
            window.configuredIdealSize,
            CGSize(width: KikiSettingsDefaults.windowWidth, height: KikiSettingsDefaults.windowHeight)
        )
        XCTAssertEqual(window.configuredMinimumSize, CGSize(width: 440, height: 330))
        XCTAssertEqual(
            window.configuredMaximumSize,
            CGSize(
                width: KikiSettingsDefaults.maximumWindowWidth,
                height: KikiSettingsDefaults.maximumWindowHeight
            )
        )
    }

    func testRegisteredWindowOwnsConfigurationVisibilityAndClose() {
        let controller = KikiSettingsWindowController(
            frameAutosaveName: "KikiSettingsTests.Window",
            minimumContentSize: CGSize(width: 420, height: 320)
        )
        let window = FakeSettingsWindow()

        controller.register(managedWindow: window)

        XCTAssertEqual(window.configuredAutosaveName, "KikiSettingsTests.Window")
        XCTAssertEqual(
            window.configuredIdealSize,
            CGSize(width: KikiSettingsDefaults.windowWidth, height: KikiSettingsDefaults.windowHeight)
        )
        XCTAssertEqual(window.configuredMinimumSize, CGSize(width: 420, height: 320))
        XCTAssertEqual(
            window.configuredMaximumSize,
            CGSize(
                width: KikiSettingsDefaults.maximumWindowWidth,
                height: KikiSettingsDefaults.maximumWindowHeight
            )
        )
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
    private(set) var configuredIdealSize: CGSize?
    private(set) var configuredMinimumSize: CGSize?
    private(set) var configuredMaximumSize: CGSize?
    private(set) var didClose = false

    func configure(
        frameAutosaveName: String,
        idealContentSize: CGSize,
        minimumContentSize: CGSize,
        maximumContentSize: CGSize
    ) {
        configuredAutosaveName = frameAutosaveName
        configuredIdealSize = idealContentSize
        configuredMinimumSize = minimumContentSize
        configuredMaximumSize = maximumContentSize
    }

    func close() {
        didClose = true
        isVisible = false
    }
}
