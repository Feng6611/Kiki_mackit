import AppKit
import Foundation
import OSLog

public enum KikiTriggerCorner: String, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .topLeft:
            return String(localized: "Top Left", bundle: .main, comment: "Trigger-corner label.")
        case .topRight:
            return String(localized: "Top Right", bundle: .main, comment: "Trigger-corner label.")
        case .bottomLeft:
            return String(localized: "Bottom Left", bundle: .main, comment: "Trigger-corner label.")
        case .bottomRight:
            return String(localized: "Bottom Right", bundle: .main, comment: "Trigger-corner label.")
        }
    }
}

public struct KikiTriggerCornerConfiguration: Equatable {
    public static let `default` = KikiTriggerCornerConfiguration()
    public static let disabled = KikiTriggerCornerConfiguration(isEnabled: false)

    public var isEnabled: Bool
    public var corner: KikiTriggerCorner
    public var edgeSize: CGFloat
    public var dwellDuration: TimeInterval
    public var cooldownDuration: TimeInterval
    public var pollingInterval: TimeInterval

    public init(
        isEnabled: Bool = true,
        corner: KikiTriggerCorner = .topRight,
        edgeSize: CGFloat = 32,
        dwellDuration: TimeInterval = 0.45,
        cooldownDuration: TimeInterval = 1.5,
        pollingInterval: TimeInterval = 0.08
    ) {
        self.isEnabled = isEnabled
        self.corner = corner
        self.edgeSize = max(1, edgeSize)
        self.dwellDuration = max(0, dwellDuration)
        self.cooldownDuration = max(0, cooldownDuration)
        self.pollingInterval = max(0.016, pollingInterval)
    }
}

public enum KikiTriggerCornerGeometry {
    public static func contains(
        point: CGPoint,
        screenFrames: [CGRect],
        corner: KikiTriggerCorner,
        edgeSize: CGFloat
    ) -> Bool {
        let size = max(1, edgeSize)

        return screenFrames.contains { frame in
            cornerRect(in: frame, corner: corner, edgeSize: size).contains(point)
        }
    }

    public static func cornerRect(
        in frame: CGRect,
        corner: KikiTriggerCorner,
        edgeSize: CGFloat
    ) -> CGRect {
        let size = max(1, edgeSize)

        switch corner {
        case .topLeft:
            return CGRect(
                x: frame.minX,
                y: frame.maxY - size,
                width: size,
                height: size
            )
        case .topRight:
            return CGRect(
                x: frame.maxX - size,
                y: frame.maxY - size,
                width: size,
                height: size
            )
        case .bottomLeft:
            return CGRect(
                x: frame.minX,
                y: frame.minY,
                width: size,
                height: size
            )
        case .bottomRight:
            return CGRect(
                x: frame.maxX - size,
                y: frame.minY,
                width: size,
                height: size
            )
        }
    }
}

public struct KikiTriggerCornerActivationState {
    private var enteredAt: Date?
    private var isArmed = true
    private var cooldownUntil: Date?

    public init() {}

    public mutating func reset() {
        enteredAt = nil
        isArmed = true
        cooldownUntil = nil
    }

    public mutating func disarmUntilExit() {
        enteredAt = nil
        isArmed = false
        cooldownUntil = nil
    }

    public mutating func update(
        isInsideCorner: Bool,
        now: Date,
        dwellDuration: TimeInterval,
        cooldownDuration: TimeInterval
    ) -> Bool {
        guard isInsideCorner else {
            enteredAt = nil
            isArmed = true
            return false
        }

        if let cooldownUntil {
            guard now >= cooldownUntil else {
                return false
            }
            self.cooldownUntil = nil
        }

        guard isArmed else {
            return false
        }

        guard let enteredAt else {
            self.enteredAt = now
            return false
        }

        guard now.timeIntervalSince(enteredAt) >= max(0, dwellDuration) else {
            return false
        }

        self.enteredAt = nil
        isArmed = false
        cooldownUntil = now.addingTimeInterval(max(0, cooldownDuration))
        return true
    }
}

@MainActor
public final class KikiTriggerCornerMonitor {
    public typealias ConfigurationProvider = () -> KikiTriggerCornerConfiguration
    public typealias MouseLocationProvider = () -> CGPoint
    public typealias ScreenFramesProvider = () -> [CGRect]
    public typealias TriggerHandler = (_ corner: KikiTriggerCorner) -> Void

    private let configurationProvider: ConfigurationProvider
    private let mouseLocationProvider: MouseLocationProvider
    private let screenFramesProvider: ScreenFramesProvider
    private let onTrigger: TriggerHandler
    private let logger: Logger
    private var activationState = KikiTriggerCornerActivationState()
    private var lastWasInsideCorner = false
    private var timer: Timer?

    public convenience init(
        configuration: KikiTriggerCornerConfiguration = .default,
        mouseLocationProvider: @escaping MouseLocationProvider = { NSEvent.mouseLocation },
        screenFramesProvider: @escaping ScreenFramesProvider = { NSScreen.screens.map(\.frame) },
        onTrigger: @escaping () -> Void
    ) {
        self.init(
            configurationProvider: { configuration },
            mouseLocationProvider: mouseLocationProvider,
            screenFramesProvider: screenFramesProvider,
            onTrigger: { _ in onTrigger() }
        )
    }

    public convenience init(
        configuration: KikiTriggerCornerConfiguration = .default,
        mouseLocationProvider: @escaping MouseLocationProvider = { NSEvent.mouseLocation },
        screenFramesProvider: @escaping ScreenFramesProvider = { NSScreen.screens.map(\.frame) },
        onTrigger: @escaping TriggerHandler
    ) {
        self.init(
            configurationProvider: { configuration },
            mouseLocationProvider: mouseLocationProvider,
            screenFramesProvider: screenFramesProvider,
            onTrigger: onTrigger
        )
    }

    public convenience init(
        configurationProvider: @escaping ConfigurationProvider,
        mouseLocationProvider: @escaping MouseLocationProvider = { NSEvent.mouseLocation },
        screenFramesProvider: @escaping ScreenFramesProvider = { NSScreen.screens.map(\.frame) },
        onTrigger: @escaping () -> Void
    ) {
        self.init(
            configurationProvider: configurationProvider,
            mouseLocationProvider: mouseLocationProvider,
            screenFramesProvider: screenFramesProvider,
            onTrigger: { _ in onTrigger() }
        )
    }

    public init(
        configurationProvider: @escaping ConfigurationProvider,
        mouseLocationProvider: @escaping MouseLocationProvider = { NSEvent.mouseLocation },
        screenFramesProvider: @escaping ScreenFramesProvider = { NSScreen.screens.map(\.frame) },
        onTrigger: @escaping TriggerHandler
    ) {
        self.configurationProvider = configurationProvider
        self.mouseLocationProvider = mouseLocationProvider
        self.screenFramesProvider = screenFramesProvider
        self.onTrigger = onTrigger
        self.logger = Logger(subsystem: "dev.kkuk.kiki", category: "TriggerCorner")
    }

    deinit {
        timer?.invalidate()
    }

    public var isRunning: Bool {
        timer != nil
    }

    public func disarmUntilExit() {
        activationState.disarmUntilExit()
    }

    public func start() {
        guard timer == nil else {
            return
        }

        let configuration = configurationProvider()
        activationState.disarmUntilExit()
        lastWasInsideCorner = false
        let timer = Timer(timeInterval: configuration.pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        logger.info("Trigger corner monitor started. enabled=\(configuration.isEnabled), corner=\(configuration.corner.rawValue, privacy: .public)")
    }

    public func stop() {
        let wasRunning = timer != nil
        timer?.invalidate()
        timer = nil
        activationState.reset()
        lastWasInsideCorner = false

        if wasRunning {
            logger.info("Trigger corner monitor stopped.")
        }
    }

    public func evaluate(now: Date = Date()) {
        evaluate(point: mouseLocationProvider(), now: now)
    }

    public func evaluate(point: CGPoint, now: Date = Date()) {
        let configuration = configurationProvider()
        guard configuration.isEnabled else {
            activationState.reset()
            lastWasInsideCorner = false
            return
        }

        let screenFrames = screenFramesProvider()
        let isInsideCorner = KikiTriggerCornerGeometry.contains(
            point: point,
            screenFrames: screenFrames,
            corner: configuration.corner,
            edgeSize: configuration.edgeSize
        )

        if isInsideCorner != lastWasInsideCorner {
            if isInsideCorner {
                logger.info("Pointer entered trigger corner. corner=\(configuration.corner.rawValue, privacy: .public), point=\(point.debugDescription, privacy: .public), screens=\(screenFrames.count)")
            } else {
                logger.info("Pointer exited trigger corner. corner=\(configuration.corner.rawValue, privacy: .public), point=\(point.debugDescription, privacy: .public)")
            }
            lastWasInsideCorner = isInsideCorner
        }

        if activationState.update(
            isInsideCorner: isInsideCorner,
            now: now,
            dwellDuration: configuration.dwellDuration,
            cooldownDuration: configuration.cooldownDuration
        ) {
            logger.info("Trigger corner dwell completed. corner=\(configuration.corner.rawValue, privacy: .public)")
            onTrigger(configuration.corner)
        }
    }
}
