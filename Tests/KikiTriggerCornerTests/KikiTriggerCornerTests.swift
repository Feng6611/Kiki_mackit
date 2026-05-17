import CoreGraphics
import XCTest
@testable import KikiTriggerCorner

@MainActor
final class KikiTriggerCornerTests: XCTestCase {
    func testGeometryHandlesMultipleScreens() {
        let frames = [
            CGRect(x: 0, y: 0, width: 100, height: 100),
            CGRect(x: 100, y: 0, width: 100, height: 100)
        ]

        XCTAssertTrue(
            KikiTriggerCornerGeometry.contains(
                point: CGPoint(x: 198, y: 98),
                screenFrames: frames,
                corner: .topRight,
                edgeSize: 12
            )
        )
        XCTAssertFalse(
            KikiTriggerCornerGeometry.contains(
                point: CGPoint(x: 150, y: 50),
                screenFrames: frames,
                corner: .topRight,
                edgeSize: 12
            )
        )
    }

    func testActivationRequiresDwellAndExitToRearm() {
        var activation = KikiTriggerCornerActivationState()
        let start = Date(timeIntervalSince1970: 0)

        XCTAssertFalse(
            activation.update(
                isInsideCorner: true,
                now: start,
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertFalse(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(0.44),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertTrue(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(0.46),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertFalse(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(2.2),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )

        XCTAssertFalse(
            activation.update(
                isInsideCorner: false,
                now: start.addingTimeInterval(2.3),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertFalse(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(2.4),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertTrue(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(2.9),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
    }

    func testActivationCanWaitForExitBeforeArming() {
        var activation = KikiTriggerCornerActivationState()
        let start = Date(timeIntervalSince1970: 0)

        activation.disarmUntilExit()

        XCTAssertFalse(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(1),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertFalse(
            activation.update(
                isInsideCorner: false,
                now: start.addingTimeInterval(1.1),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertFalse(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(1.2),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
        XCTAssertTrue(
            activation.update(
                isInsideCorner: true,
                now: start.addingTimeInterval(1.7),
                dwellDuration: 0.45,
                cooldownDuration: 1.5
            )
        )
    }

    func testMonitorCallsHandlerAfterDwell() {
        var pointer = CGPoint(x: 99, y: 99)
        var triggeredCorners: [KikiTriggerCorner] = []
        let monitor = KikiTriggerCornerMonitor(
            configuration: KikiTriggerCornerConfiguration(corner: .topRight),
            mouseLocationProvider: { pointer },
            screenFramesProvider: { [CGRect(x: 0, y: 0, width: 100, height: 100)] },
            onTrigger: { corner in
                triggeredCorners.append(corner)
            }
        )
        let start = Date(timeIntervalSince1970: 0)

        monitor.evaluate(now: start)
        monitor.evaluate(now: start.addingTimeInterval(0.44))
        XCTAssertTrue(triggeredCorners.isEmpty)

        monitor.evaluate(now: start.addingTimeInterval(0.46))
        XCTAssertEqual(triggeredCorners, [.topRight])

        monitor.evaluate(now: start.addingTimeInterval(2.2))
        XCTAssertEqual(triggeredCorners, [.topRight])

        pointer = CGPoint(x: 50, y: 50)
        monitor.evaluate(now: start.addingTimeInterval(2.3))
        pointer = CGPoint(x: 99, y: 99)
        monitor.evaluate(now: start.addingTimeInterval(2.4))
        monitor.evaluate(now: start.addingTimeInterval(2.9))

        XCTAssertEqual(triggeredCorners, [.topRight, .topRight])
    }

    func testMonitorReadsDynamicConfiguration() {
        var configuration = KikiTriggerCornerConfiguration(
            isEnabled: false,
            corner: .topRight,
            dwellDuration: 0.2
        )
        var triggerCount = 0
        let monitor = KikiTriggerCornerMonitor(
            configurationProvider: { configuration },
            mouseLocationProvider: { CGPoint(x: 1, y: 1) },
            screenFramesProvider: { [CGRect(x: 0, y: 0, width: 100, height: 100)] },
            onTrigger: {
                triggerCount += 1
            }
        )
        let start = Date(timeIntervalSince1970: 0)

        monitor.evaluate(now: start)
        monitor.evaluate(now: start.addingTimeInterval(1))
        XCTAssertEqual(triggerCount, 0)

        configuration.isEnabled = true
        configuration.corner = .bottomLeft

        monitor.evaluate(now: start.addingTimeInterval(1.1))
        monitor.evaluate(now: start.addingTimeInterval(1.31))
        XCTAssertEqual(triggerCount, 1)
    }
}
