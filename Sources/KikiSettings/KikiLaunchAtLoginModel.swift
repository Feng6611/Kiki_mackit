#if os(macOS) || targetEnvironment(macCatalyst)
import AppKit
import Combine

/// Observable launch-at-login state for a Settings row.
///
/// `isOn` is `true` for `.enabled` and for `.requiresApproval`: the person has
/// asked for the item and only System Settings stands in the way, so the
/// switch stays on and the row explains the pending approval instead of
/// snapping back. Read `status` for the real state.
///
/// The model refreshes when the app becomes active again, so returning from
/// System Settings updates the row.
@MainActor
public final class KikiLaunchAtLoginModel: ObservableObject {
	@Published public private(set) var status: LaunchAtLoginStatus

	public var isOn: Bool {
		status == .enabled || status == .requiresApproval
	}

	private let service: any LaunchAtLoginService
	private var activation: AnyCancellable?

	public convenience init() {
		self.init(service: SystemLaunchAtLoginService())
	}

	public init(
		service: any LaunchAtLoginService,
		notificationCenter: NotificationCenter = .default
	) {
		self.service = service
		status = service.status
		activation = notificationCenter
			.publisher(for: NSApplication.didBecomeActiveNotification)
			.sink { [weak self] _ in
				MainActor.assumeIsolated { self?.refresh() }
			}
	}

	@discardableResult
	public func set(_ enabled: Bool) -> LaunchAtLoginOutcome {
		let outcome = LaunchAtLoginOutcome.apply(enabled, to: service)
		refresh()
		return outcome
	}

	public func refresh() {
		status = service.status
	}
}
#endif
