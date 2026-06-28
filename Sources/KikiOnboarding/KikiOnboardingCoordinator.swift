import AppKit
import SwiftUI

@MainActor
public final class KikiOnboardingCoordinator: ObservableObject {
    public let configuration: KikiOnboardingConfiguration
    public let completionStore: KikiOnboardingCompletionStore
    private let onPaywallHandoff: (@MainActor () -> Void)?
    private let onFinished: (@MainActor () -> Void)?

    @Published public private(set) var currentStepIndex: Int = 0
    private var windowController: KikiOnboardingWindowController?

    public init(
        configuration: KikiOnboardingConfiguration,
        completionStore: KikiOnboardingCompletionStore = KikiOnboardingUserDefaultsCompletionStore(),
        onPaywallHandoff: (@MainActor () -> Void)? = nil,
        onFinished: (@MainActor () -> Void)? = nil
    ) {
        self.configuration = configuration
        self.completionStore = completionStore
        self.onPaywallHandoff = onPaywallHandoff
        self.onFinished = onFinished
    }

    public var isCompleted: Bool {
        completionStore.isCompleted(forKey: configuration.completionKey)
    }

    public var currentStep: KikiOnboardingStep? {
        guard configuration.steps.indices.contains(currentStepIndex) else { return nil }
        return configuration.steps[currentStepIndex]
    }

    public var canGoBack: Bool { currentStepIndex > 0 }

    public func startIfNeeded() {
        guard isCompleted == false else { return }
        start()
    }

    public func start() {
        currentStepIndex = 0
        presentWindow()
        handleCurrentStepIfNonInteractive()
    }

    public func advance() {
        let nextIndex = currentStepIndex + 1
        if nextIndex >= configuration.steps.count {
            finish()
            return
        }
        currentStepIndex = nextIndex
        handleCurrentStepIfNonInteractive()
    }

    public func back() {
        guard canGoBack else { return }
        currentStepIndex -= 1
    }

    public func finish() {
        completionStore.markCompleted(forKey: configuration.completionKey)
        windowController?.close()
        windowController = nil
        onFinished?()
    }

    public func resetCompletion() {
        completionStore.reset(forKey: configuration.completionKey)
    }

    private func handleCurrentStepIfNonInteractive() {
        guard case .paywallHandoff = currentStep else { return }
        if let onPaywallHandoff {
            onPaywallHandoff()
        } else {
            advance()
        }
    }

    private func presentWindow() {
        if let windowController {
            windowController.show()
            return
        }
        let controller = KikiOnboardingWindowController(
            title: configuration.windowTitle,
            frameAutosaveName: configuration.windowAutosaveName,
            onClose: { [weak self] in
                self?.handleWindowClosed()
            }
        ) {
            KikiOnboardingFlowContainer(coordinator: self)
        }
        windowController = controller
        controller.show()
    }

    private func handleWindowClosed() {
        windowController = nil
    }
}

private struct KikiOnboardingFlowContainer: View {
    @ObservedObject var coordinator: KikiOnboardingCoordinator

    var body: some View {
        Group {
            switch coordinator.currentStep {
            case .welcome(let content):
                welcomeView(content: content)
            case .features(let content):
                featureView(content: content)
            case .permission(let content):
                permissionView(content: content)
            case .success(let content):
                successView(content: content)
            case .paywallHandoff:
                paywallHandoffPlaceholder
            case .custom(_, let viewBuilder):
                viewBuilder()
            case .none:
                EmptyView()
            }
        }
        .id(coordinator.currentStepIndex)
    }

    private func welcomeView(content: KikiOnboardingWelcomeContent) -> some View {
        KikiOnboardingScaffold(
            appName: coordinator.configuration.appName,
            title: content.title,
            bodyText: content.body,
            iconSystemName: content.iconSystemName,
            rows: content.rows,
            primaryAction: KikiOnboardingAction(
                title: content.continueTitle,
                action: { coordinator.advance() }
            ),
            secondaryAction: content.skipTitle.map { title in
                KikiOnboardingAction(title: title, action: { coordinator.finish() })
            },
            tint: coordinator.configuration.tint
        )
    }

    private func featureView(content: KikiOnboardingFeatureContent) -> some View {
        KikiOnboardingScaffold(
            appName: coordinator.configuration.appName,
            title: content.title,
            bodyText: content.body,
            iconSystemName: content.iconSystemName,
            rows: content.rows,
            primaryAction: KikiOnboardingAction(
                title: content.continueTitle,
                action: { coordinator.advance() }
            ),
            secondaryAction: content.backTitle.flatMap { title in
                coordinator.canGoBack
                    ? KikiOnboardingAction(title: title, action: { coordinator.back() })
                    : nil
            },
            tint: coordinator.configuration.tint
        )
    }

    private func permissionView(content: KikiOnboardingPermissionContent) -> some View {
        KikiOnboardingScaffold(
            appName: coordinator.configuration.appName,
            title: content.title,
            bodyText: content.body,
            iconSystemName: content.iconSystemName,
            rows: [],
            permissionRow: content.permissionRow,
            primaryAction: KikiOnboardingAction(
                title: content.continueTitle,
                action: { coordinator.advance() }
            ),
            secondaryAction: content.backTitle.flatMap { title in
                coordinator.canGoBack
                    ? KikiOnboardingAction(title: title, action: { coordinator.back() })
                    : nil
            },
            tint: coordinator.configuration.tint
        )
    }

    private func successView(content: KikiOnboardingSuccessContent) -> some View {
        KikiOnboardingScaffold(
            appName: coordinator.configuration.appName,
            title: content.title,
            bodyText: content.body,
            iconSystemName: content.iconSystemName,
            rows: [],
            primaryAction: KikiOnboardingAction(
                title: content.finishTitle,
                action: { coordinator.advance() }
            ),
            tint: coordinator.configuration.tint
        )
    }

    private var paywallHandoffPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(width: 560, height: 520)
    }
}
