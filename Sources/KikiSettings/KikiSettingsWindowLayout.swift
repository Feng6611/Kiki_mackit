import Foundation
import CoreGraphics

/// Shared content-size contract for SwiftUI and the registered AppKit window.
public struct KikiSettingsWindowLayout: Equatable, Sendable {
    public let ideal: CGSize
    public let minimum: CGSize
    public let maximum: CGSize

    public init(
        ideal: CGSize = CGSize(width: 500, height: 620),
        minimum: CGSize = CGSize(width: 500, height: 480),
        maximum: CGSize = CGSize(width: 500, height: 780)
    ) {
        self.minimum = CGSize(width: max(1, minimum.width), height: max(1, minimum.height))
        self.maximum = CGSize(
            width: max(self.minimum.width, maximum.width),
            height: max(self.minimum.height, maximum.height)
        )
        self.ideal = CGSize(
            width: min(max(ideal.width, self.minimum.width), self.maximum.width),
            height: min(max(ideal.height, self.minimum.height), self.maximum.height)
        )
    }
}
