#if os(macOS) || targetEnvironment(macCatalyst)
import KikiDesign
import SwiftUI

/// Launch-at-login switch that tells the person when macOS is holding the item.
///
/// All strings are caller-provided and already localized. While the model is
/// `.requiresApproval` the row shows `approvalNote` and a button that opens
/// System Settings › Login Items. A failed request just reverts the switch to
/// the real state; hosts that want to react read the outcome from
/// `model.set(_:)`.
public struct KikiSettingsLaunchAtLoginRow: View {
	private let title: String
	private let systemImage: String?
	private let approvalNote: String
	private let openLoginItemsTitle: String
	@ObservedObject private var model: KikiLaunchAtLoginModel

	public init(
		title: String,
		systemImage: String? = nil,
		approvalNote: String,
		openLoginItemsTitle: String,
		model: KikiLaunchAtLoginModel
	) {
		self.title = title
		self.systemImage = systemImage
		self.approvalNote = approvalNote
		self.openLoginItemsTitle = openLoginItemsTitle
		self.model = model
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: KikiDesignTokens.Spacing.xs) {
			KikiSettingsToggleRow(title, isOn: isOn, systemImage: systemImage)

			if model.status == .requiresApproval {
				KikiSettingsHelperText(approvalNote)
				Button(openLoginItemsTitle) {
					LaunchAtLogin.openSystemSettingsLoginItems()
				}
				.buttonStyle(.borderless)
			}
		}
	}

	private var isOn: Binding<Bool> {
		Binding(
			get: { model.isOn },
			set: { model.set($0) }
		)
	}
}
#endif
