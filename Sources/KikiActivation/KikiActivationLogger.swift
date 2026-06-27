import OSLog

public protocol KikiActivationLogger {
    @MainActor func log(_ message: String)
}

public struct KikiDefaultActivationLogger: KikiActivationLogger {
    private let logger = Logger(subsystem: "kiki.mackit", category: "kiki.activation")

    public init() {}

    @MainActor
    public func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }
}
