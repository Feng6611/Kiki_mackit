import AppKit
import CoreGraphics
import Foundation

struct KikiAuthorizationSettingsWindowSnapshot: Equatable {
    let processID: pid_t
    let frame: CGRect
    let visibleFrame: CGRect
}

enum KikiAuthorizationSettingsWindowLocator {
    static let bundleIdentifier = "com.apple.systempreferences"

    static var isSystemSettingsFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier
    }

    static func frontmostWindow() -> KikiAuthorizationSettingsWindowSnapshot? {
        guard isSystemSettingsFrontmost else {
            return nil
        }

        guard let settingsApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first else {
            return nil
        }

        guard let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            .zero
        ) as? [[String: Any]] else {
            return nil
        }

        let windows = windowInfo.compactMap { info -> KikiAuthorizationSettingsWindowSnapshot? in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == settingsApp.processIdentifier,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: Any] else {
                return nil
            }

            let cgFrame = CGRect(
                x: number(bounds, "X"),
                y: number(bounds, "Y"),
                width: number(bounds, "Width"),
                height: number(bounds, "Height")
            )

            guard cgFrame.width > 320, cgFrame.height > 240 else {
                return nil
            }

            let converted = convertToAppKitFrame(cgFrame)
            return KikiAuthorizationSettingsWindowSnapshot(
                processID: ownerPID,
                frame: converted.frame,
                visibleFrame: converted.visibleFrame
            )
        }

        return windows.max {
            $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
        }
    }

    private static func number(_ dictionary: [String: Any], _ key: String) -> CGFloat {
        if let value = dictionary[key] as? CGFloat {
            return value
        }

        if let value = dictionary[key] as? NSNumber {
            return CGFloat(value.doubleValue)
        }

        return 0
    }

    private static func convertToAppKitFrame(_ cgFrame: CGRect) -> (frame: CGRect, visibleFrame: CGRect) {
        let screenMatches = NSScreen.screens.compactMap { screen -> ScreenGeometry? in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }

            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            return ScreenGeometry(
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                coreGraphicsBounds: CGDisplayBounds(displayID)
            )
        }

        guard let screen = screenMatches
            .filter({ $0.coreGraphicsBounds.intersects(cgFrame) })
            .max(by: { lhs, rhs in
                lhs.coreGraphicsBounds.intersection(cgFrame).area
                    < rhs.coreGraphicsBounds.intersection(cgFrame).area
            }) else {
            return (
                frame: cgFrame,
                visibleFrame: NSScreen.main?.visibleFrame ?? cgFrame
            )
        }

        let x = screen.frame.minX + (cgFrame.minX - screen.coreGraphicsBounds.minX)
        let yFromTop = cgFrame.minY - screen.coreGraphicsBounds.minY
        let y = screen.frame.maxY - yFromTop - cgFrame.height

        return (
            frame: CGRect(x: x, y: y, width: cgFrame.width, height: cgFrame.height),
            visibleFrame: screen.visibleFrame
        )
    }
}

private struct ScreenGeometry {
    let frame: CGRect
    let visibleFrame: CGRect
    let coreGraphicsBounds: CGRect
}

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}
