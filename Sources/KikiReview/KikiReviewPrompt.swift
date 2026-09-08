import AppKit
import KikiDesign
import KikiWindow
import SwiftUI

public struct KikiReviewPromptConfiguration: Equatable, Sendable {
    public var windowTitle: String
    public var title: String
    public var message: String
    public var primaryActionTitle: String
    public var secondaryActionTitle: String

    public init(
        windowTitle: String,
        title: String,
        message: String,
        primaryActionTitle: String,
        secondaryActionTitle: String
    ) {
        self.windowTitle = windowTitle
        self.title = title
        self.message = message
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
    }
}

public enum KikiReviewPromptAction: Equatable, Sendable {
    case review
    case notNow
    case closed
}

@MainActor
public struct KikiReviewPromptView: View {
    private let configuration: KikiReviewPromptConfiguration
    private let icon: NSImage
    private let tint: Color
    private let onReview: () -> Void
    private let onNotNow: () -> Void
    private let onClose: () -> Void
    private var reportSize: ((CGSize) -> Void)?

    public init(
        configuration: KikiReviewPromptConfiguration,
        icon: NSImage? = nil,
        tint: Color = .accentColor,
        onReview: @escaping () -> Void,
        onNotNow: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.icon = icon ?? NSApplication.shared.applicationIconImage
        self.tint = tint
        self.onReview = onReview
        self.onNotNow = onNotNow
        self.onClose = onClose
    }

    public var body: some View {
        KikiSheetShell(
            width: KikiReviewPromptDefaults.width,
            minimumHeight: KikiReviewPromptDefaults.height,
            idealHeight: KikiReviewPromptDefaults.height,
            maximumHeight: KikiReviewPromptDefaults.maximumHeight,
            showsCloseButton: true,
            onClose: onClose
        ) {
            VStack(spacing: 14) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(
                        cornerRadius: KikiDesignTokens.CornerRadius.iconLarge,
                        style: .continuous
                    ))
                    .shadow(color: .black.opacity(0.10), radius: 8, y: 4)

                Text(configuration.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(configuration.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 30)
            .padding(.top, 24)
        } footer: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { actionButtons }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .trailing, spacing: 10) { actionButtons }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .accessibilityElement(children: .contain)
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear { reportSize?(proxy.size) }
                .onChange(of: proxy.size) { reportSize?($0) }
        })
    }

    private var actionButtons: some View {
        Group {
            Button(configuration.secondaryActionTitle, action: onNotNow)
                .buttonStyle(.bordered)
                .controlSize(.large)
            Button(configuration.primaryActionTitle, action: onReview)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint)
                .keyboardShortcut(.defaultAction)
        }
    }

    func reportingSize(_ action: @escaping (CGSize) -> Void) -> Self {
        var view = self
        view.reportSize = action
        return view
    }
}

public enum KikiReviewPromptDefaults {
    public static let width: CGFloat = 420
    public static let height: CGFloat = 310
    public static let maximumHeight: CGFloat = 560
}

@MainActor
public final class KikiReviewPromptController {
    private var windowController: KikiSingleWindowController<KikiReviewPromptView>?
    private var pendingAction: KikiReviewPromptAction?
    private var actionHandler: ((KikiReviewPromptAction) -> Void)?

    public init() {}

    public var isVisible: Bool {
        windowController?.isVisible == true
    }

    public func show(
        configuration: KikiReviewPromptConfiguration,
        icon: NSImage? = nil,
        tint: Color = .accentColor,
        onAction: @escaping (KikiReviewPromptAction) -> Void
    ) {
        if let windowController, windowController.isVisible {
            windowController.show()
            return
        }

        pendingAction = nil
        actionHandler = onAction

        let controller = KikiSingleWindowController(
            configuration: .transparentUtility(
                title: configuration.windowTitle,
                size: CGSize(width: KikiReviewPromptDefaults.width, height: KikiReviewPromptDefaults.height),
                hiddenButtons: .all
            ),
            onClose: { [weak self] in
                self?.handleWindowClosed()
            }
        ) { [weak self] in
            KikiReviewPromptView(
                configuration: configuration,
                icon: icon,
                tint: tint,
                onReview: { self?.finish(with: .review) },
                onNotNow: { self?.finish(with: .notNow) },
                onClose: { self?.finish(with: .closed) }
            ).reportingSize { [weak self] size in
                guard let window = self?.windowController?.window,
                      abs(window.contentLayoutRect.height - size.height) > 0.5 else { return }
                window.setContentSize(size)
            }
        }
        windowController = controller
        controller.show()
    }

    public func close() {
        finish(with: .closed)
    }

    private func finish(with action: KikiReviewPromptAction) {
        guard windowController != nil, pendingAction == nil else { return }
        pendingAction = action
        windowController?.close()
    }

    private func handleWindowClosed() {
        let action = pendingAction ?? .closed
        let handler = actionHandler
        pendingAction = nil
        actionHandler = nil
        windowController = nil
        handler?(action)
    }
}
