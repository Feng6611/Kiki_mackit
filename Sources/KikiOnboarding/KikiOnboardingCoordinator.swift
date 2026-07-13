import AppKit
import SwiftUI

@MainActor
public final class KikiOnboardingCoordinator: ObservableObject {
    enum NavigationDirection {
        case forward
        case backward
    }

    public let configuration: KikiOnboardingConfiguration
    public let completionStore: KikiOnboardingCompletionStore
    private let onPaywallHandoff: (@MainActor () -> Void)?
    private let onFinished: (@MainActor () -> Void)?

    @Published public private(set) var currentStepIndex: Int = 0
    @Published private(set) var navigationDirection: NavigationDirection = .forward
    private var windowController: KikiOnboardingWindowController?
    private var isClosingAfterFinish = false
    private var hasFinishedCurrentPresentation = false

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

    public var canSkip: Bool { configuration.canSkip }

    public var isVisible: Bool { windowController?.isVisible == true }

    /// Escape hatch for App-owned window sessions (activation policy,
    /// miniaturize-and-return flows). Nil while the window is not presented.
    public var window: NSWindow? { windowController?.window }

    public func startIfNeeded() {
        guard isCompleted == false else { return }
        start()
    }

    public func start() {
        hasFinishedCurrentPresentation = false
        navigationDirection = .forward
        currentStepIndex = 0
        guard configuration.steps.isEmpty == false else {
            finish()
            return
        }
        presentWindow()
        handleCurrentStepIfNonInteractive()
    }

    public func advance() {
        let nextIndex = currentStepIndex + 1
        if nextIndex >= configuration.steps.count {
            finish()
            return
        }
        navigationDirection = .forward
        currentStepIndex = nextIndex
        handleCurrentStepIfNonInteractive()
    }

    public func back() {
        guard canGoBack else { return }
        navigationDirection = .backward
        currentStepIndex -= 1
        handleCurrentStepIfNonInteractive()
    }

    public func skip() {
        guard configuration.canSkip else { return }
        finish()
    }

    public func close() {
        windowController?.close()
    }

    public func finish() {
        guard hasFinishedCurrentPresentation == false else {
            return
        }

        hasFinishedCurrentPresentation = true
        completionStore.markCompleted(forKey: configuration.completionKey)
        isClosingAfterFinish = windowController != nil
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
            size: configuration.windowSize,
            minimumSize: configuration.minimumWindowSize,
            onClose: { [weak self] in
                self?.handleWindowClosed()
            }
        ) {
            KikiOnboardingFlowContainer(coordinator: self)
        }
        windowController = controller
        controller.show()
    }

    func handleWindowClosed() {
        windowController = nil
        if isClosingAfterFinish {
            isClosingAfterFinish = false
            return
        }

        guard configuration.closeDisposition == .complete,
              hasFinishedCurrentPresentation == false else {
            return
        }

        hasFinishedCurrentPresentation = true
        completionStore.markCompleted(forKey: configuration.completionKey)
        onFinished?()
    }
}

private struct KikiOnboardingFlowContainer: View {
    @ObservedObject var coordinator: KikiOnboardingCoordinator

    var body: some View {
        ZStack {
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
                    viewBuilder(navigation)
                case .none:
                    EmptyView()
                }
            }
            // A stable per-page identity is required for custom/AnyView steps.
            // Without it SwiftUI updates the existing hierarchy in place, so
            // only the text changes and the transition never runs.
            .id(coordinator.currentStepIndex)
            .transition(pageTransition)
        }
        .animation(.easeInOut(duration: 0.22), value: coordinator.currentStepIndex)
        .frame(
            width: coordinator.configuration.windowSize.width,
            height: coordinator.configuration.windowSize.height
        )
        .clipped()
    }

    private var pageTransition: AnyTransition {
        let insertionEdge: Edge = coordinator.navigationDirection == .forward ? .trailing : .leading
        let removalEdge: Edge = coordinator.navigationDirection == .forward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var navigation: KikiOnboardingNavigation {
        KikiOnboardingNavigation(
            advance: { coordinator.advance() },
            back: { coordinator.back() },
            skip: { coordinator.skip() },
            finish: { coordinator.finish() }
        )
    }

    private var stepCount: Int {
        coordinator.configuration.steps.count
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
            skipAction: coordinator.canSkip
                ? content.skipTitle.map { title in
                    KikiOnboardingAction(title: title, action: { coordinator.skip() })
                }
                : nil,
            tint: coordinator.configuration.tint,
            size: coordinator.configuration.windowSize,
            stepIndex: coordinator.currentStepIndex,
            stepCount: stepCount
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
            backAction: content.backTitle.flatMap { title in
                coordinator.canGoBack
                    ? KikiOnboardingAction(title: title, action: { coordinator.back() })
                    : nil
            },
            tint: coordinator.configuration.tint,
            size: coordinator.configuration.windowSize,
            stepIndex: coordinator.currentStepIndex,
            stepCount: stepCount
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
            backAction: content.backTitle.flatMap { title in
                coordinator.canGoBack
                    ? KikiOnboardingAction(title: title, action: { coordinator.back() })
                    : nil
            },
            tint: coordinator.configuration.tint,
            size: coordinator.configuration.windowSize,
            stepIndex: coordinator.currentStepIndex,
            stepCount: stepCount
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
            tint: coordinator.configuration.tint,
            size: coordinator.configuration.windowSize,
            stepIndex: coordinator.currentStepIndex,
            stepCount: stepCount
        )
    }

    private var paywallHandoffPlaceholder: some View {
        KikiOnboardingLoadingScaffold(
            appName: coordinator.configuration.appName,
            title: "Loading…",
            tint: coordinator.configuration.tint,
            size: coordinator.configuration.windowSize
        )
    }
}
