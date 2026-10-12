import Foundation
@testable import KikiSettings
import XCTest

@MainActor
final class KikiSettingsWindowControllerTests: XCTestCase {
    func testSharedLayoutConfiguresRegisteredWindow() {
        let layout = KikiSettingsWindowLayout(
            ideal: CGSize(width: 720, height: 800),
            minimum: CGSize(width: 640, height: 500),
            maximum: CGSize(width: 900, height: 1000),
            heightPolicy: .fitsContent
        )
        let controller = KikiSettingsWindowController(frameAutosaveName: "LayoutTest", layout: layout)
        let window = FakeSettingsWindow()
        controller.register(managedWindow: window)
        XCTAssertEqual(controller.layout, layout)
        XCTAssertEqual(window.configuredIdealSize, layout.ideal)
        XCTAssertEqual(window.configuredMinimumSize, layout.minimum)
        XCTAssertEqual(window.configuredMaximumSize, layout.maximum)
        XCTAssertEqual(window.configuredHeightPolicy, .fitsContent)
    }

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

    func testLayoutHeightPolicyDefaultsToFixed() {
        XCTAssertEqual(KikiSettingsWindowLayout().heightPolicy, .fixed)
        XCTAssertEqual(
            KikiSettingsWindowLayout(
                ideal: CGSize(width: 500, height: 620),
                minimum: CGSize(width: 500, height: 480),
                maximum: CGSize(width: 500, height: 780)
            ).heightPolicy,
            .fixed
        )
    }

    func testFittedHeightIsClampedCachedAndDeduplicated() {
        let layout = KikiSettingsWindowLayout(heightPolicy: .fitsContent)
        let controller = KikiSettingsWindowController(frameAutosaveName: "FittedHeightTest", layout: layout)
        let window = FakeSettingsWindow()

        controller.updateFittedContentHeight(layout.maximum.height + 100)
        controller.register(managedWindow: window)
        XCTAssertEqual(window.fittedHeights, [layout.maximum.height])

        controller.updateFittedContentHeight(layout.maximum.height)
        controller.updateFittedContentHeight(layout.ideal.height)
        XCTAssertEqual(window.fittedHeights, [layout.maximum.height, layout.ideal.height])
    }
}

@MainActor
private final class FakeSettingsWindow: KikiSettingsWindowManaging {
    var isVisible = true
    private(set) var configuredAutosaveName: String?
    private(set) var configuredIdealSize: CGSize?
    private(set) var configuredMinimumSize: CGSize?
    private(set) var configuredMaximumSize: CGSize?
    private(set) var configuredHeightPolicy: KikiSettingsWindowHeightPolicy?
    private(set) var fittedHeights: [CGFloat] = []
    private(set) var didClose = false

    func configure(
        frameAutosaveName: String,
        idealContentSize: CGSize,
        minimumContentSize: CGSize,
        maximumContentSize: CGSize,
        heightPolicy: KikiSettingsWindowHeightPolicy
    ) {
        configuredAutosaveName = frameAutosaveName
        configuredIdealSize = idealContentSize
        configuredMinimumSize = minimumContentSize
        configuredMaximumSize = maximumContentSize
        configuredHeightPolicy = heightPolicy
    }

    func fitContentHeight(_ height: CGFloat) {
        fittedHeights.append(height)
    }

    func close() {
        didClose = true
        isVisible = false
    }
}
