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
            configuration: .utility(
                title: title,
                size: CGSize(width: 560, height: 520),
                minimumSize: CGSize(width: 560, height: 520),
                frameAutosaveName: frameAutosaveName
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
