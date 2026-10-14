import AppKit
import Foundation
@testable import KikiSettings
import SwiftUI
import Testing

private struct FakeError: LocalizedError {
	var errorDescription: String? { "boom" }
}

/// Stands in for SMAppService; nothing here touches the real login item.
private final class FakeLoginService: LaunchAtLoginService {
	var status: LaunchAtLoginStatus
	var statusAfterRegister: LaunchAtLoginStatus = .enabled
	var statusAfterUnregister: LaunchAtLoginStatus = .notRegistered
	var registerError: Error?
	/// Status the item reaches when `register()` throws anyway.
	var statusWhenRegisterThrows: LaunchAtLoginStatus?
	var unregisterError: Error?
	private(set) var calls: [String] = []

	init(status: LaunchAtLoginStatus = .notRegistered) { self.status = status }

	func register() throws {
		calls.append("register")
		if let registerError {
			if let statusWhenRegisterThrows { status = statusWhenRegisterThrows }
			throw registerError
		}
		status = statusAfterRegister
	}

	func unregister() throws {
		calls.append("unregister")
		if let unregisterError { throw unregisterError }
		status = statusAfterUnregister
	}
}

@MainActor
struct LaunchAtLoginTests {
	@Test("Register that takes effect is enabled")
	func registerEnabled() {
		let service = FakeLoginService()
		let model = KikiLaunchAtLoginModel(service: service)
		#expect(model.set(true) == .enabled)
		#expect(model.status == .enabled)
		#expect(model.isOn)
	}

	@Test("Register that waits for approval is requiresApproval, and the switch stays on")
	func registerRequiresApproval() {
		let service = FakeLoginService()
		service.statusAfterRegister = .requiresApproval
		let model = KikiLaunchAtLoginModel(service: service)
		#expect(model.set(true) == .requiresApproval)
		#expect(model.status == .requiresApproval)
		#expect(model.isOn)
	}

	@Test("A thrown register is failed with the message, not success")
	func registerThrows() {
		let service = FakeLoginService()
		service.registerError = FakeError()
		let model = KikiLaunchAtLoginModel(service: service)
		#expect(model.set(true) == .failed(message: "boom"))
		#expect(model.status == .notRegistered)
		#expect(!model.isOn)
	}

	@Test("A throw is failed even if the status then reads enabled")
	func registerThrowsButEnabled() {
		let service = FakeLoginService(status: .requiresApproval)
		service.registerError = FakeError()
		service.statusWhenRegisterThrows = .enabled
		#expect(LaunchAtLoginOutcome.apply(true, to: service) == .failed(message: "boom"))
		#expect(service.status == .enabled)
	}

	@Test("Register without effect reports failure")
	func registerNoEffect() {
		let service = FakeLoginService()
		service.statusAfterRegister = .notFound
		guard case .failed = LaunchAtLoginOutcome.apply(true, to: service) else {
			Issue.record("expected failed")
			return
		}
	}

	@Test("Enabling an enabled item does not unregister it")
	func enableWhenEnabledLeavesItAlone() {
		let service = FakeLoginService(status: .enabled)
		#expect(LaunchAtLoginOutcome.apply(true, to: service) == .enabled)
		#expect(service.calls.isEmpty)
	}

	@Test("Unregister is disabled")
	func unregisterDisables() {
		let service = FakeLoginService(status: .enabled)
		let model = KikiLaunchAtLoginModel(service: service)
		#expect(model.set(false) == .disabled)
		#expect(!model.isOn)
	}

	@Test("Unregister that throws because nothing was registered is disabled")
	func unregisterNotRegistered() {
		let service = FakeLoginService(status: .notRegistered)
		service.unregisterError = FakeError()
		#expect(LaunchAtLoginOutcome.apply(false, to: service) == .disabled)
	}

	@Test("Unregister that leaves the item on is failed")
	func unregisterFails() {
		let service = FakeLoginService(status: .enabled)
		service.unregisterError = FakeError()
		#expect(LaunchAtLoginOutcome.apply(false, to: service) == .failed(message: "boom"))
	}

	@Test("Refresh reads the service")
	func refreshReadsService() {
		let service = FakeLoginService(status: .requiresApproval)
		let model = KikiLaunchAtLoginModel(service: service)
		#expect(model.status == .requiresApproval)
		service.status = .enabled
		model.refresh()
		#expect(model.status == .enabled)
	}

	@Test("Becoming active again refreshes")
	func refreshOnActivation() {
		let center = NotificationCenter()
		let service = FakeLoginService(status: .requiresApproval)
		let model = KikiLaunchAtLoginModel(service: service, notificationCenter: center)
		service.status = .enabled
		center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
		#expect(model.status == .enabled)
	}

	@Test("Row is constructible")
	func rowConstructs() {
		let model = KikiLaunchAtLoginModel(service: FakeLoginService(status: .requiresApproval))
		_ = KikiSettingsLaunchAtLoginRow(
			title: "Launch at Login",
			systemImage: "power",
			approvalNote: "Allow it in Login Items.",
			openLoginItemsTitle: "Open Login Items",
			model: model
		)
	}
}
