import AppKit
import KikiCore

@MainActor
public final class KikiActivationPolicyCoordinator {
    private let prewarmsThroughDockOnFirstActivation: Bool
    private let logger: KikiActivationLogger?
    private var previousFrontmostApplication: NSRunningApplication?
    private var didPrewarmDock = false

    public init(
        prewarmsThroughDockOnFirstActivation: Bool = false,
        logger: KikiActivationLogger? = nil
    ) {
        self.prewarmsThroughDockOnFirstActivation = prewarmsThroughDockOnFirstActivation
        self.logger = logger
    }

    public func start() {
        apply(policy: .accessory)
        logger?.log("Activation coordinator started in accessory mode")
    }

    public func begin(reason: String) {
        captureFrontmostApplicationIfNeeded()
        prewarmDockIfNeeded()
        apply(policy: .regular)

        if #available(macOS 14.0, *) {
            if let frontmostApplication = NSWorkspace.shared.frontmostApplication,
               frontmostApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier,
               NSRunningApplication.current.activate(from: frontmostApplication) {
                logger?.log("Promoted app to regular for reason: \(reason)")
                return
            }

            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }

        logger?.log("Promoted app to regular for reason: \(reason)")
    }

    public func end() {
        defer {
            previousFrontmostApplication = nil
            apply(policy: .accessory)
        }

        guard let previousFrontmostApplication else {
            logger?.log("Ended promoted state without previous frontmost app")
            return
        }

        if #available(macOS 14.0, *) {
            NSApplication.shared.yieldActivation(to: previousFrontmostApplication)
            _ = previousFrontmostApplication.activate(
                from: NSRunningApplication.current,
                options: []
            )
        } else {
            _ = previousFrontmostApplication.activate(options: [])
        }
        logger?.log("Restored previous frontmost app after promoted state")
    }

    public func reset(
        toPolicy policy: NSApplication.ActivationPolicy,
        reason: String
    ) {
        previousFrontmostApplication = nil
        apply(policy: policy)
        logger?.log("Reset activation policy to \(String(describing: policy)) for reason: \(reason)")
    }

    private func captureFrontmostApplicationIfNeeded() {
        guard let frontmostApplication = NSWorkspace.shared.frontmostApplication,
              frontmostApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            previousFrontmostApplication = nil
            return
        }

        previousFrontmostApplication = frontmostApplication
    }

    private func prewarmDockIfNeeded() {
        guard prewarmsThroughDockOnFirstActivation, didPrewarmDock == false else {
            return
        }

        didPrewarmDock = true
        apply(policy: .regular)
        apply(policy: .accessory)
        logger?.log("Prewarmed Dock before first promoted activation")
    }

    private func apply(policy: NSApplication.ActivationPolicy) {
        NSApplication.shared.setActivationPolicy(policy)
    }
}
