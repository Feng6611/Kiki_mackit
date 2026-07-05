import KikiWindow
import SwiftUI

@MainActor
public final class KikiOnboardingWindowController {
    private let windowController: KikiSingleWindowController<AnyView>

    public init(
        title: String = "Welcome",
        frameAutosaveName: String = "KikiOnboarding.Window",
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.windowController = KikiSingleWindowController(
            configuration: .transparentUtility(
                title: title,
                size: KikiOnboardingDefaults.windowSize,
                minimumSize: KikiOnboardingDefaults.windowSize,
                frameAutosaveName: frameAutosaveName,
                hiddenButtons: .all
            ),
            onClose: onClose
        ) {
            AnyView(content())
        }
    }

    public init(
        title: String = "Welcome",
        frameAutosaveName: String = "KikiOnboarding.Window",
        size: CGSize,
        minimumSize: CGSize? = KikiOnboardingDefaults.windowSize,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.windowController = KikiSingleWindowController(
            configuration: .transparentUtility(
                title: title,
                size: size,
                minimumSize: minimumSize,
                frameAutosaveName: frameAutosaveName,
                hiddenButtons: .all
            ),
            onClose: onClose
        ) {
            AnyView(content())
        }
    }

    public var isVisible: Bool {
        windowController.isVisible
    }

    public func show() {
        windowController.show()
    }

    public func close() {
        windowController.close()
    }
}
