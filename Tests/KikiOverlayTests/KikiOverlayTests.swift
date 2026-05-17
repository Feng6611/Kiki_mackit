import KikiOverlay
import Testing

struct KikiOverlayTests {
    @Test("Screen edge overlay presets expose expected metadata")
    func screenEdgeOverlayPresetsExposeExpectedMetadata() {
        let lockStarted = KikiScreenEdgeOverlayPresentation.lockStarted(
            title: "Keyboard locked",
            subtitle: "Hold shortcut to unlock"
        )
        #expect(lockStarted.title == "Keyboard locked")
        #expect(lockStarted.systemImage == "lock.fill")
        #expect(lockStarted.behavior == .persistent)
        #expect(lockStarted.motion == .breathingWithEntryBurst)
        #expect(lockStarted.toastDuration == 5)
        #expect(lockStarted.edgeDuration == nil)

        let lockEnded = KikiScreenEdgeOverlayPresentation.lockEnded(title: "Keyboard unlocked")
        #expect(lockEnded.title == "Keyboard unlocked")
        #expect(lockEnded.systemImage == "checkmark")
        #expect(lockEnded.behavior == .momentary(duration: 5.35))
        #expect(lockEnded.motion == .breathingWithEntryBurst)
        #expect(lockEnded.toastDuration == 5)
        #expect(lockEnded.edgeDuration == 1.5)

        let warning = KikiScreenEdgeOverlayPresentation.warning(title: "Lock stopped")
        #expect(warning.title == "Lock stopped")
        #expect(warning.systemImage == "exclamationmark.triangle.fill")
        #expect(warning.behavior == .momentary(duration: 5.35))
        #expect(warning.motion == .blink)
        #expect(warning.edgeDuration == 1.8)
    }

    @Test("Screen edge overlay default style exposes soft breathing values")
    func screenEdgeOverlayDefaultStyleExposesSoftBreathingValues() {
        let style = KikiScreenEdgeOverlayStyle.default

        #expect(style.edgeLineWidth == 3)
        #expect(style.glowDepth == 62)
        #expect(style.sideGlowDepth == 58)
        #expect(style.cornerThickness == 5)
        #expect(style.toastWidth == 340)
        #expect(style.breathingDuration == KikiScreenEdgeOverlayStyle.defaultBreathingDuration)
        #expect(style.breathingMinOpacity == 0.5)
        #expect(style.breathingMaxOpacity == 0.82)
        #expect(style.breathingGlowScale == 0.16)
        #expect(style.breathingLineWidthBoost == 0.45)
        #expect(style.entryBurstDuration == 0.52)
        #expect(style.entryBurstLineWidthBoost == 1.5)
    }

    @Test("Screen edge overlay style factory maps intensity as composite glow")
    func screenEdgeOverlayStyleFactoryMapsIntensityAsCompositeGlow() {
        let borderOnly = KikiScreenEdgeOverlayStyle.screenEdge(glowIntensity: 0)

        #expect(borderOnly.edgeLineWidth > 0)
        #expect(borderOnly.glowDepth == 0)
        #expect(borderOnly.sideGlowDepth == 0)
        #expect(borderOnly.washOpacity == 0)
        #expect(borderOnly.cornerThickness == 0)
        #expect(borderOnly.cornerShadowRadius == 0)
        #expect(borderOnly.entryBurstOpacityBoost > 0)
        #expect(borderOnly.entryBurstLineWidthBoost > 0)
        #expect(borderOnly.breathingGlowScale > 0)
        #expect(borderOnly.breathingLineWidthBoost > 0)
        #expect(borderOnly.breathingDuration == KikiScreenEdgeOverlayStyle.defaultBreathingDuration)

        let strong = KikiScreenEdgeOverlayStyle.screenEdge(glowIntensity: 1)

        #expect(strong.glowDepth > borderOnly.glowDepth)
        #expect(strong.cornerThickness > borderOnly.cornerThickness)
        #expect(strong.entryBurstLineWidthBoost > borderOnly.entryBurstLineWidthBoost)
        #expect(strong.breathingGlowScale > borderOnly.breathingGlowScale)
        #expect(strong.breathingLineWidthBoost > borderOnly.breathingLineWidthBoost)
        #expect(strong.breathingDuration == KikiScreenEdgeOverlayStyle.defaultBreathingDuration)
    }

    @MainActor
    @Test("Screen edge overlay controller is constructible and can hide")
    func screenEdgeOverlayControllerIsConstructibleAndCanHide() {
        let controller = KikiScreenEdgeOverlayController()
        #expect(!controller.isPresenting)

        controller.show(.lockStarted(title: "Locked", subtitle: "Testing"))
        #expect(controller.isPresenting)

        controller.updateStyle(.screenEdge(glowIntensity: 0.5))

        controller.hideImmediately()
        #expect(!controller.isPresenting)
    }
}
