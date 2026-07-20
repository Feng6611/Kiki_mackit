import KikiWindow
import SwiftUI

@MainActor
public final class KikiPaywallWindowController<Content: View> {
    private let windowController: KikiSingleWindowController<Content>

    public init(
        title: String = "Upgrade",
        size: CGSize = CGSize(
            width: KikiPaywallDefaults.windowWidth,
            height: KikiPaywallDefaults.windowHeight
        ),
        minimumSize: CGSize? = nil,
        frameAutosaveName: String? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.windowController = KikiSingleWindowController(
            configuration: .utility(
                title: title,
                size: size,
                minimumSize: minimumSize,
                frameAutosaveName: frameAutosaveName
            ),
            onClose: onClose,
            content: content
        )
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
