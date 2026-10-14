#if os(macOS) || targetEnvironment(macCatalyst)
import SwiftUI
import ServiceManagement
import os.log

public enum LaunchAtLogin {
	private static let logger = Logger(subsystem: "com.sindresorhus.LaunchAtLogin", category: "main")
	fileprivate static let observable = Observable()

	/**
	Toggle “launch at login” for your app or check whether it's enabled.

	`true` means the login item is actually enabled. An item that macOS holds in
	`.requiresApproval` reads as `false`; use ``status`` and ``setEnabled(_:)``
	when the app needs to tell the two apart.
	*/
	public static var isEnabled: Bool {
		get { status == .enabled }
		set { setEnabled(newValue) }
	}

	/// The login item's real state, including “registered but waiting for the
	/// user in System Settings › Login Items”.
	public static var status: LaunchAtLoginStatus {
		SystemLaunchAtLoginService().status
	}

	/**
	Registers or unregisters the app as a login item and reports what happened.

	The outcome is classified from the status read back after the call, and a
	thrown error is never reported as success. `.requiresApproval` means the
	request was accepted but macOS keeps the item off until the user allows it;
	macOS shows no prompt for that, so the app should explain it and offer
	``openSystemSettingsLoginItems()``.
	*/
	@discardableResult
	public static func setEnabled(_ enabled: Bool) -> LaunchAtLoginOutcome {
		observable.objectWillChange.send()
		let outcome = LaunchAtLoginOutcome.apply(enabled, to: SystemLaunchAtLoginService())
		if case .failed(let message) = outcome {
			logger.error("Failed to \(enabled ? "enable" : "disable") launch at login: \(message)")
		}
		return outcome
	}

	/// Opens System Settings at Login Items, where a pending item is approved.
	public static func openSystemSettingsLoginItems() {
		SMAppService.openSystemSettingsLoginItems()
	}

	/**
	Whether the app was launched at login.

	- Important: This property must only be checked in `NSApplicationDelegate#applicationDidFinishLaunching`.
	*/
	public static var wasLaunchedAtLogin: Bool {
		let event = NSAppleEventManager.shared().currentAppleEvent
		return event?.eventID == kAEOpenApplication
			&& event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
	}
}

extension LaunchAtLogin {
	final class Observable: ObservableObject {
		var isEnabled: Bool {
			get { LaunchAtLogin.isEnabled }
			set {
				LaunchAtLogin.isEnabled = newValue
			}
		}
	}
}

extension LaunchAtLogin {
	/**
	This package comes with a `LaunchAtLogin.Toggle` view which is like the built-in `Toggle` but with a predefined binding and label. Clicking the view toggles “launch at login” for your app.

	```
	struct ContentView: View {
		var body: some View {
			LaunchAtLogin.Toggle()
		}
	}
	```

	The default label is `"Launch at login"`, but it can be overridden for localization and other needs:

	```
	struct ContentView: View {
		var body: some View {
			LaunchAtLogin.Toggle {
				Text("Launch at login")
			}
		}
	}
	```
	*/
	public struct Toggle<Label: View>: View {
		@ObservedObject private var launchAtLogin = LaunchAtLogin.observable
		private let label: Label

		/**
		Creates a toggle that displays a custom label.

		- Parameters:
			- label: A view that describes the purpose of the toggle.
		*/
		public init(@ViewBuilder label: () -> Label) {
			self.label = label()
		}

		public var body: some View {
			SwiftUI.Toggle(isOn: $launchAtLogin.isEnabled) { label }
		}
	}
}

extension LaunchAtLogin.Toggle<Text> {
	/**
	Creates a toggle that generates its label from a localized string key.

	This initializer creates a ``Text`` view on your behalf with the provided `titleKey`.

	- Parameters:
		- titleKey: The key for the toggle's localized title, that describes the purpose of the toggle.
	*/
	public init(_ titleKey: LocalizedStringKey) {
		label = Text(titleKey)
	}

	/**
	Creates a toggle that generates its label from a string.

	This initializer creates a `Text` view on your behalf with the provided `title`.

	- Parameters:
		- title: A string that describes the purpose of the toggle.
	*/
	public init(_ title: some StringProtocol) {
		label = Text(title)
	}

	/**
	Creates a toggle with the default title of `Launch at login`.
	*/
	public init() {
		self.init("Launch at login")
	}
}
#endif
