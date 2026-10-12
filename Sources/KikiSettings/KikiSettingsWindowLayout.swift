import Foundation
import CoreGraphics

/// Controls whether registered Settings windows keep the configured height or
/// resize to the selected pane's fitting height.
public enum KikiSettingsWindowHeightPolicy: Equatable, Sendable {
    /// Keeps the configured ideal height. This is the default for compatibility.
    case fixed
    /// Resizes the registered window to the selected pane, within its height bounds.
    case fitsContent
}

/// Shared content-size contract for SwiftUI and the registered AppKit window.
public struct KikiSettingsWindowLayout: Equatable, Sendable {
    public let ideal: CGSize
    public let minimum: CGSize
    public let maximum: CGSize
    public let heightPolicy: KikiSettingsWindowHeightPolicy

    public init(
        ideal: CGSize = CGSize(width: 500, height: 620),
        minimum: CGSize = CGSize(width: 500, height: 480),
        maximum: CGSize = CGSize(width: 500, height: 780),
        heightPolicy: KikiSettingsWindowHeightPolicy = .fixed
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
        self.heightPolicy = heightPolicy
    }
}
