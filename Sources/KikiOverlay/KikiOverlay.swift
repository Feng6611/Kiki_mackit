import AppKit
import KikiDesign
import SwiftUI

public enum KikiScreenEdgeOverlayBehavior: Equatable {
    case persistent
    case momentary(duration: TimeInterval)
}

public enum KikiScreenEdgeOverlayMotion: Equatable {
    case breathing
    case breathingWithEntryBurst
    case blink
    case steady
}

public struct KikiScreenEdgeOverlayStyle {
    public static let defaultBreathingDuration: TimeInterval = 3.2
    public static let defaultGlowIntensity = 0.85

    public var edgeLineWidth: CGFloat
    public var glowDepth: CGFloat
    public var sideGlowDepth: CGFloat
    public var washOpacity: Double
    public var cornerLengthRatio: CGFloat
    public var maxCornerLength: CGFloat
    public var cornerThickness: CGFloat
    public var cornerShadowRadius: CGFloat
    public var toastWidth: CGFloat
    public var toastTopPadding: CGFloat
    public var toastCornerRadius: CGFloat
    public var toastIconCornerRadius: CGFloat
    public var fadeInDuration: TimeInterval
    public var fadeOutDuration: TimeInterval
    public var toastFadeOutDuration: TimeInterval
    public var entryBurstDuration: TimeInterval
    public var entryBurstOpacityBoost: Double
    public var entryBurstLineWidthBoost: CGFloat
    public var breathingGlowScale: CGFloat
    public var breathingLineWidthBoost: CGFloat
    public var breathingDuration: TimeInterval
    public var breathingMinOpacity: Double
    public var breathingMaxOpacity: Double
    public var blinkDuration: TimeInterval
    public var panelLevel: NSWindow.Level

    init(
        edgeLineWidth: CGFloat = 3,
        glowDepth: CGFloat = 62,
        sideGlowDepth: CGFloat = 58,
        washOpacity: Double = 0.034,
        cornerLengthRatio: CGFloat = 0.085,
        maxCornerLength: CGFloat = 120,
        cornerThickness: CGFloat = 5,
        cornerShadowRadius: CGFloat = 16,
        toastWidth: CGFloat = 340,
        toastTopPadding: CGFloat = 60,
        toastCornerRadius: CGFloat = 18,
        toastIconCornerRadius: CGFloat = 9,
        fadeInDuration: TimeInterval = 0.2,
        fadeOutDuration: TimeInterval = 0.42,
        toastFadeOutDuration: TimeInterval = 0.35,
        entryBurstDuration: TimeInterval = 0.52,
        entryBurstOpacityBoost: Double = 0.22,
        entryBurstLineWidthBoost: CGFloat = 1.5,
        breathingGlowScale: CGFloat = 0.16,
        breathingLineWidthBoost: CGFloat = 0.45,
        breathingDuration: TimeInterval = 3.2,
        breathingMinOpacity: Double = 0.5,
        breathingMaxOpacity: Double = 0.82,
        blinkDuration: TimeInterval = 0.28,
        panelLevel: NSWindow.Level = .screenSaver
    ) {
        self.edgeLineWidth = edgeLineWidth
        self.glowDepth = glowDepth
        self.sideGlowDepth = sideGlowDepth
        self.washOpacity = washOpacity
        self.cornerLengthRatio = cornerLengthRatio
        self.maxCornerLength = maxCornerLength
        self.cornerThickness = cornerThickness
        self.cornerShadowRadius = cornerShadowRadius
        self.toastWidth = toastWidth
        self.toastTopPadding = toastTopPadding
        self.toastCornerRadius = toastCornerRadius
        self.toastIconCornerRadius = toastIconCornerRadius
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
        self.toastFadeOutDuration = toastFadeOutDuration
        self.entryBurstDuration = entryBurstDuration
        self.entryBurstOpacityBoost = entryBurstOpacityBoost
        self.entryBurstLineWidthBoost = entryBurstLineWidthBoost
        self.breathingGlowScale = breathingGlowScale
        self.breathingLineWidthBoost = breathingLineWidthBoost
        self.breathingDuration = breathingDuration
        self.breathingMinOpacity = breathingMinOpacity
        self.breathingMaxOpacity = breathingMaxOpacity
        self.blinkDuration = blinkDuration
        self.panelLevel = panelLevel
    }

    public init(
        glowIntensity: Double = Self.defaultGlowIntensity,
        toastWidth: CGFloat = 340,
        panelLevel: NSWindow.Level = .screenSaver,
        toastDuration: TimeInterval = 5
    ) {
        let intensity = min(max(glowIntensity, 0), 1)
        self.init(
            edgeLineWidth: 2.5 + 0.75 * CGFloat(intensity),
            glowDepth: 88 * CGFloat(intensity),
            sideGlowDepth: 82 * CGFloat(intensity),
            washOpacity: 0.044 * intensity,
            cornerThickness: 6.8 * CGFloat(intensity),
            cornerShadowRadius: 21 * CGFloat(intensity),
            toastWidth: toastWidth,
            toastFadeOutDuration: min(max(toastDuration * 0.07, 0.25), 0.45),
            entryBurstOpacityBoost: 0.1 + 0.2 * intensity,
            entryBurstLineWidthBoost: 0.7 + 1.5 * CGFloat(intensity),
            breathingGlowScale: 0.14 + 0.16 * CGFloat(intensity),
            breathingLineWidthBoost: 0.22 + 0.34 * CGFloat(intensity),
            breathingDuration: Self.defaultBreathingDuration,
            breathingMinOpacity: 0.48 + 0.08 * intensity,
            breathingMaxOpacity: 0.7 + 0.16 * intensity,
            panelLevel: panelLevel
        )
    }

    public static let `default` = KikiScreenEdgeOverlayStyle(
        edgeLineWidth: 3,
        glowDepth: 62,
        sideGlowDepth: 58,
        washOpacity: 0.034,
        cornerLengthRatio: 0.085,
        maxCornerLength: 120,
        cornerThickness: 5,
        cornerShadowRadius: 16,
        toastWidth: 340,
        toastTopPadding: 60,
        toastCornerRadius: 18,
        toastIconCornerRadius: 9,
        fadeInDuration: 0.2,
        fadeOutDuration: 0.42,
        toastFadeOutDuration: 0.35,
        entryBurstDuration: 0.52,
        entryBurstOpacityBoost: 0.22,
        entryBurstLineWidthBoost: 1.5,
        breathingGlowScale: 0.16,
        breathingLineWidthBoost: 0.45,
        breathingDuration: defaultBreathingDuration,
        breathingMinOpacity: 0.5,
        breathingMaxOpacity: 0.82,
        blinkDuration: 0.28,
        panelLevel: .screenSaver
    )

    public static func screenEdge(
        glowIntensity: Double = 0.85,
        panelLevel: NSWindow.Level = .screenSaver
    ) -> KikiScreenEdgeOverlayStyle {
        let intensity = min(max(glowIntensity, 0), 1)

        return KikiScreenEdgeOverlayStyle(
            edgeLineWidth: 2.5 + 0.75 * CGFloat(intensity),
            glowDepth: 88 * CGFloat(intensity),
            sideGlowDepth: 82 * CGFloat(intensity),
            washOpacity: 0.044 * intensity,
            cornerThickness: 6.8 * CGFloat(intensity),
            cornerShadowRadius: 21 * CGFloat(intensity),
            entryBurstOpacityBoost: 0.1 + 0.2 * intensity,
            entryBurstLineWidthBoost: 0.7 + 1.5 * CGFloat(intensity),
            breathingGlowScale: 0.14 + 0.16 * CGFloat(intensity),
            breathingLineWidthBoost: 0.22 + 0.34 * CGFloat(intensity),
            breathingDuration: Self.defaultBreathingDuration,
            breathingMinOpacity: 0.48 + 0.08 * intensity,
            breathingMaxOpacity: 0.7 + 0.16 * intensity,
            panelLevel: panelLevel
        )
    }
}

public enum KikiOverlayTone {
    case alert
    case success
    case warning
}

public struct KikiScreenEdgeOverlayPresentation {
    public var title: String
    public var subtitle: String
    public var systemImage: String
    public var tint: Color
    public var companionTint: Color
    public var behavior: KikiScreenEdgeOverlayBehavior
    public var motion: KikiScreenEdgeOverlayMotion
    public var toastDuration: TimeInterval
    public var edgeDuration: TimeInterval?

    public init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        companionTint: Color,
        behavior: KikiScreenEdgeOverlayBehavior,
        motion: KikiScreenEdgeOverlayMotion,
        toastDuration: TimeInterval = 5,
        edgeDuration: TimeInterval? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.companionTint = companionTint
        self.behavior = behavior
        self.motion = motion
        self.toastDuration = toastDuration
        self.edgeDuration = edgeDuration
    }

    public static func lockStarted(
        tone: KikiOverlayTone = .alert,
        title: String = "Locked",
        subtitle: String = "",
        systemImage: String = "lock.fill",
        tint: Color? = nil,
        companionTint: Color? = nil,
        motion: KikiScreenEdgeOverlayMotion = .breathingWithEntryBurst,
        toastDuration: TimeInterval = 5
    ) -> KikiScreenEdgeOverlayPresentation {
        let palette = palette(for: tone)
        return KikiScreenEdgeOverlayPresentation(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            tint: tint ?? palette.tint,
            companionTint: companionTint ?? palette.companionTint,
            behavior: .persistent,
            motion: motion,
            toastDuration: toastDuration,
            edgeDuration: nil
        )
    }

    public static func lockEnded(
        tone: KikiOverlayTone = .success,
        title: String = "Unlocked",
        subtitle: String = "",
        systemImage: String = "checkmark",
        tint: Color? = nil,
        companionTint: Color? = nil,
        motion: KikiScreenEdgeOverlayMotion = .breathingWithEntryBurst,
        toastDuration: TimeInterval = 5,
        edgeDuration: TimeInterval = 1.5
    ) -> KikiScreenEdgeOverlayPresentation {
        let palette = palette(for: tone)
        return KikiScreenEdgeOverlayPresentation(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            tint: tint ?? palette.tint,
            companionTint: companionTint ?? palette.companionTint,
            behavior: .momentary(duration: toastDuration + 0.35),
            motion: motion,
            toastDuration: toastDuration,
            edgeDuration: edgeDuration
        )
    }

    public static func warning(
        tone: KikiOverlayTone = .warning,
        title: String = "Warning",
        subtitle: String = "",
        systemImage: String = "exclamationmark.triangle.fill",
        tint: Color? = nil,
        companionTint: Color? = nil,
        motion: KikiScreenEdgeOverlayMotion = .blink,
        toastDuration: TimeInterval = 5,
        edgeDuration: TimeInterval = 1.8
    ) -> KikiScreenEdgeOverlayPresentation {
        let palette = palette(for: tone)
        return KikiScreenEdgeOverlayPresentation(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            tint: tint ?? palette.tint,
            companionTint: companionTint ?? palette.companionTint,
            behavior: .momentary(duration: toastDuration + 0.35),
            motion: motion,
            toastDuration: toastDuration,
            edgeDuration: edgeDuration
        )
    }

    private static func palette(for tone: KikiOverlayTone) -> (tint: Color, companionTint: Color) {
        switch tone {
        case .alert:
            return (KikiScreenEdgeOverlayPalette.orange, KikiScreenEdgeOverlayPalette.deepOrange)
        case .success:
            return (KikiScreenEdgeOverlayPalette.success, KikiScreenEdgeOverlayPalette.deepSuccess)
        case .warning:
            return (KikiScreenEdgeOverlayPalette.warning, KikiScreenEdgeOverlayPalette.orange)
        }
    }
}

enum KikiScreenEdgeOverlayPalette {
    static let orange = Color(red: 1.0, green: 0.49, blue: 0.12)
    static let brightOrange = Color(red: 1.0, green: 0.68, blue: 0.28)
    static let deepOrange = Color(red: 0.86, green: 0.25, blue: 0.03)
    static let success = Color(red: 0.0, green: 0.62, blue: 0.34)
    static let deepSuccess = Color(red: 0.0, green: 0.42, blue: 0.26)
    static let warning = Color(red: 1.0, green: 0.34, blue: 0.12)
}

@MainActor
public final class KikiScreenEdgeOverlayController {
    private var style: KikiScreenEdgeOverlayStyle
    private var panels: [NSPanel] = []
    private var hideWorkItem: DispatchWorkItem?
    private var screenObserver: NSObjectProtocol?
    private var currentPresentation: KikiScreenEdgeOverlayPresentation?
    private var presentationID = 0

    public private(set) var isPresenting = false

    public init(style: KikiScreenEdgeOverlayStyle = .default) {
        self.style = style
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshForCurrentMode()
            }
        }
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    public func show(_ presentation: KikiScreenEdgeOverlayPresentation) {
        presentationID += 1
        let currentPresentationID = presentationID
        currentPresentation = presentation
        isPresenting = true
        hideWorkItem?.cancel()

        rebuildPanels(presentation: presentation)
        panels.forEach { panel in
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = style.fadeInDuration
            panels.forEach { $0.animator().alphaValue = 1 }
        }

        guard case .momentary(let duration) = presentation.behavior else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.fadeOut(presentationID: currentPresentationID)
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + duration,
            execute: workItem
        )
    }

    public func updateStyle(_ style: KikiScreenEdgeOverlayStyle) {
        self.style = style
        panels.forEach { $0.level = style.panelLevel }
        refreshForCurrentMode()
    }

    public func hideImmediately() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        currentPresentation = nil
        isPresenting = false
        panels.forEach { $0.orderOut(nil) }
    }

    private func rebuildPanels(presentation: KikiScreenEdgeOverlayPresentation) {
        let existingPanels = panels
        panels = NSScreen.screens.enumerated().map { index, screen in
            let panel = index < existingPanels.count ? existingPanels[index] : makePanel()
            configure(panel: panel, screen: screen, presentation: presentation)
            return panel
        }

        if existingPanels.count > panels.count {
            existingPanels.dropFirst(panels.count).forEach { $0.orderOut(nil) }
        }
    }

    private func configure(panel: NSPanel, screen: NSScreen, presentation: KikiScreenEdgeOverlayPresentation) {
        panel.setFrame(screen.frame, display: true)
        panel.contentView = NSHostingView(
            rootView: KikiScreenEdgeOverlayView(
                presentation: presentation,
                style: style
            )
        )
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isMovable = false
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = style.panelLevel
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary,
            .transient
        ]
        return panel
    }

    private func fadeOut(presentationID: Int) {
        guard presentationID == self.presentationID else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = style.fadeOutDuration
            panels.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, presentationID == self.presentationID else {
                    return
                }
                self.currentPresentation = nil
                self.isPresenting = false
                self.panels.forEach { $0.orderOut(nil) }
            }
        }
    }

    private func refreshForCurrentMode() {
        guard let currentPresentation else {
            return
        }
        rebuildPanels(presentation: currentPresentation)
        panels.forEach {
            $0.alphaValue = 1
            $0.orderFrontRegardless()
        }
    }
}

private struct KikiScreenEdgeOverlayView: View {
    let presentation: KikiScreenEdgeOverlayPresentation
    let style: KikiScreenEdgeOverlayStyle

    @State private var appearedAt = Date()
    @State private var edgeVisible = false
    @State private var traceProgress: CGFloat = 0
    @State private var toastVisible = false
    @State private var entryBurst = false

    private func activeOpacity(breathAmount: Double) -> Double {
        guard edgeVisible else {
            return 0
        }

        let baseOpacity: Double
        switch presentation.motion {
        case .steady:
            baseOpacity = style.breathingMaxOpacity
        case .breathing, .breathingWithEntryBurst:
            baseOpacity = style.breathingMinOpacity
                + (style.breathingMaxOpacity - style.breathingMinOpacity) * breathAmount
        case .blink:
            baseOpacity = 0.3 + 0.7 * breathAmount
        }

        guard entryBurst else {
            return baseOpacity
        }
        return min(1, baseOpacity + style.entryBurstOpacityBoost)
    }

    private func activeLineWidth(breathAmount: Double) -> CGFloat {
        style.edgeLineWidth
            + activeBreathingLineWidthBoost(breathAmount: breathAmount)
            + (entryBurst ? style.entryBurstLineWidthBoost : 0)
    }

    private func activeBreathingLineWidthBoost(breathAmount: Double) -> CGFloat {
        switch presentation.motion {
        case .breathing, .breathingWithEntryBurst:
            return style.breathingLineWidthBoost * CGFloat(breathAmount)
        case .blink:
            return style.breathingLineWidthBoost * CGFloat(0.25 + 0.75 * breathAmount)
        case .steady:
            return 0
        }
    }

    private func activeGlowScale(breathAmount: Double) -> CGFloat {
        guard edgeVisible else {
            return 0
        }

        let baseScale: CGFloat
        switch presentation.motion {
        case .breathing, .breathingWithEntryBurst:
            baseScale = 1 + style.breathingGlowScale * CGFloat(breathAmount)
        case .blink:
            baseScale = 0.96 + 0.16 * CGFloat(breathAmount)
        case .steady:
            baseScale = 1
        }

        return entryBurst ? baseScale + style.breathingGlowScale * 0.65 : baseScale
    }

    private func motionAmount(at date: Date) -> Double {
        switch presentation.motion {
        case .steady:
            return 1
        case .breathing, .breathingWithEntryBurst:
            return oscillationAmount(
                at: date,
                cycleDuration: max(1.8, style.breathingDuration),
                startsLow: true
            )
        case .blink:
            return oscillationAmount(
                at: date,
                cycleDuration: max(0.16, style.blinkDuration * 2),
                startsLow: false
            )
        }
    }

    private func oscillationAmount(
        at date: Date,
        cycleDuration: TimeInterval,
        startsLow: Bool
    ) -> Double {
        let elapsed = max(0, date.timeIntervalSince(appearedAt))
        let progress = elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
        let phaseOffset = startsLow ? -Double.pi / 2 : 0
        let raw = (sin(progress * 2 * Double.pi + phaseOffset) + 1) / 2
        return min(max(raw, 0), 1)
    }

    var body: some View {
        TimelineView(.periodic(from: appearedAt, by: 1.0 / 30.0)) { timeline in
            let breathAmount = motionAmount(at: timeline.date)
            let opacity = activeOpacity(breathAmount: breathAmount)

            ZStack(alignment: .top) {
                KikiScreenEdgeGlowLayer(
                    color: presentation.tint,
                    companionColor: presentation.companionTint,
                    opacity: opacity,
                    glowScale: activeGlowScale(breathAmount: breathAmount),
                    style: style
                )

                KikiScreenBorderShape()
                    .trim(from: 0, to: traceProgress)
                    .stroke(
                        presentation.tint.opacity(opacity),
                        style: StrokeStyle(
                            lineWidth: activeLineWidth(breathAmount: breathAmount),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .padding(2)

                KikiCornerAccentLayer(
                    color: presentation.tint,
                    opacity: opacity,
                    style: style
                )

                KikiEdgeFeedbackToast(
                    title: presentation.title,
                    subtitle: presentation.subtitle,
                    systemImage: presentation.systemImage,
                    tint: presentation.tint,
                    style: style
                )
                .padding(.top, style.toastTopPadding)
                .opacity(toastVisible ? 1 : 0)
                .offset(y: toastVisible ? 0 : -10)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            appearedAt = Date()
            let shouldBurst = presentation.motion == .breathingWithEntryBurst
            entryBurst = shouldBurst

            withAnimation(.easeOut(duration: 0.42)) {
                edgeVisible = true
                traceProgress = 1
                toastVisible = true
            }

            if shouldBurst {
                DispatchQueue.main.asyncAfter(deadline: .now() + style.entryBurstDuration) {
                    withAnimation(.easeOut(duration: 0.36)) {
                        entryBurst = false
                    }
                }
            }

            if let edgeDuration = presentation.edgeDuration {
                DispatchQueue.main.asyncAfter(deadline: .now() + edgeDuration) {
                    withAnimation(.easeOut(duration: 0.34)) {
                        edgeVisible = false
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + presentation.toastDuration) {
                withAnimation(.easeInOut(duration: style.toastFadeOutDuration)) {
                    toastVisible = false
                }
            }
        }
    }
}

private struct KikiEdgeFeedbackToast: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let style: KikiScreenEdgeOverlayStyle

    var body: some View {
        let toastShape = RoundedRectangle(cornerRadius: style.toastCornerRadius, style: .continuous)

        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: style.toastIconCornerRadius, style: .continuous)
                    .fill(tint)
                    .overlay {
                        RoundedRectangle(cornerRadius: style.toastIconCornerRadius, style: .continuous)
                            .fill(.white.opacity(0.12))
                    }
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .frame(width: style.toastWidth)
        .kikiMaterialSurface(
            in: toastShape,
            material: .thinMaterial,
            tint: Color(nsColor: .controlBackgroundColor),
            tintOpacity: 0.12
        )
        .overlay {
            toastShape
                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.14), radius: 16, x: 0, y: 8)
    }
}

private struct KikiScreenBorderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct KikiScreenEdgeGlowLayer: View {
    let color: Color
    let companionColor: Color
    let opacity: Double
    let glowScale: CGFloat
    let style: KikiScreenEdgeOverlayStyle

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(opacity * style.washOpacity))

            VStack(spacing: 0) {
                glow(.top)
                Spacer(minLength: 0)
                glow(.bottom)
            }

            HStack(spacing: 0) {
                glow(.leading)
                Spacer(minLength: 0)
                glow(.trailing)
            }
        }
    }

    @ViewBuilder
    private func glow(_ edge: Edge) -> some View {
        switch edge {
        case .top:
            LinearGradient(
                colors: [
                    color.opacity(opacity * 0.52),
                    companionColor.opacity(opacity * 0.18),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: style.glowDepth * glowScale)
        case .bottom:
            LinearGradient(
                colors: [
                    .clear,
                    companionColor.opacity(opacity * 0.18),
                    color.opacity(opacity * 0.50)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: style.glowDepth * glowScale)
        case .leading:
            LinearGradient(
                colors: [
                    color.opacity(opacity * 0.46),
                    companionColor.opacity(opacity * 0.15),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: style.sideGlowDepth * glowScale)
        case .trailing:
            LinearGradient(
                colors: [
                    .clear,
                    companionColor.opacity(opacity * 0.15),
                    color.opacity(opacity * 0.46)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: style.sideGlowDepth * glowScale)
        }
    }
}

private struct KikiCornerAccentLayer: View {
    let color: Color
    let opacity: Double
    let style: KikiScreenEdgeOverlayStyle

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let length = min(max(size.width, size.height) * style.cornerLengthRatio, style.maxCornerLength)

            ZStack {
                corner(length: length)
                    .position(x: length / 2, y: length / 2)

                corner(length: length)
                    .rotationEffect(.degrees(90))
                    .position(x: size.width - length / 2, y: length / 2)

                corner(length: length)
                    .rotationEffect(.degrees(180))
                    .position(x: size.width - length / 2, y: size.height - length / 2)

                corner(length: length)
                    .rotationEffect(.degrees(270))
                    .position(x: length / 2, y: size.height - length / 2)
            }
        }
    }

    private func corner(length: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(color.opacity(opacity))
                .frame(width: length, height: style.cornerThickness)
            Rectangle()
                .fill(color.opacity(opacity))
                .frame(width: style.cornerThickness, height: length)
        }
        .shadow(color: color.opacity(opacity * 0.54), radius: style.cornerShadowRadius, x: 0, y: 0)
    }
}
