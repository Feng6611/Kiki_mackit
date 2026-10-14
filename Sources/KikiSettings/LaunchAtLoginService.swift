#if os(macOS) || targetEnvironment(macCatalyst)
import ServiceManagement

/// What macOS reports for the app's login item.
public enum LaunchAtLoginStatus: Equatable, Sendable {
	case enabled
	/// Registered, but held until the user allows it in System Settings › Login Items.
	case requiresApproval
	case notRegistered
	case notFound
	case unknown
}

/// What a request to enable or disable launch at login ended up doing.
public enum LaunchAtLoginOutcome: Equatable, Sendable {
	case enabled
	case requiresApproval
	case disabled
	case failed(message: String)
}

/// The slice of `SMAppService` that launch at login needs, so tests and hosts
/// can substitute a fake instead of touching the real login item.
public protocol LaunchAtLoginService {
	var status: LaunchAtLoginStatus { get }
	func register() throws
	func unregister() throws
}

/// `SMAppService.mainApp`, the default service.
struct SystemLaunchAtLoginService: LaunchAtLoginService {
	private var service: SMAppService { .mainApp }

	var status: LaunchAtLoginStatus {
		switch service.status {
		case .enabled: return .enabled
		case .requiresApproval: return .requiresApproval
		case .notRegistered: return .notRegistered
		case .notFound: return .notFound
		@unknown default: return .unknown
		}
	}

	func register() throws { try service.register() }
	func unregister() throws { try service.unregister() }
}

extension LaunchAtLoginOutcome {
	/// Performs the request and classifies it from the status read afterwards.
	///
	/// Enabling never unregisters first. `register()` on an enabled item is a
	/// no-op, so there is nothing to refresh, and unregister-then-register
	/// would switch a working item off whenever the second call fails or lands
	/// in `.requiresApproval`. An already-enabled item is left alone.
	///
	/// A throw while enabling is always `.failed`, whatever the status says
	/// afterwards. Disabling is judged by the status alone: `unregister()`
	/// throws when nothing is registered, which is the state that was asked for.
	static func apply(_ enabled: Bool, to service: some LaunchAtLoginService) -> LaunchAtLoginOutcome {
		if enabled, service.status == .enabled {
			return .enabled
		}

		var failure: Error?
		do {
			if enabled {
				try service.register()
			} else {
				try service.unregister()
			}
		} catch {
			failure = error
		}

		let status = service.status
		func failed() -> LaunchAtLoginOutcome {
			.failed(message: failure?.localizedDescription
				?? "Login item status is \(status) after the request.")
		}

		if enabled {
			if failure != nil { return failed() }
			switch status {
			case .enabled: return .enabled
			case .requiresApproval: return .requiresApproval
			case .notRegistered, .notFound, .unknown: return failed()
			}
		}

		switch status {
		case .enabled, .requiresApproval: return failed()
		case .notRegistered, .notFound, .unknown: return .disabled
		}
	}
}
#endif
