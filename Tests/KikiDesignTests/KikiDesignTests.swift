@testable import KikiDesign
import SwiftUI
import Testing

struct KikiDesignTests {
    @MainActor
    @Test("Adaptive glass and material surface APIs are constructible")
    func adaptiveGlassAndMaterialSurfaceAreConstructible() {
        let glass = Text("Glass")
            .kikiAdaptiveGlass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))

        let surface = Text("Surface")
            .kikiMaterialSurface(
                in: RoundedRectangle(cornerRadius: 10, style: .continuous),
                tint: .accentColor
            )

        let background = Text("Window")
            .kikiWindowMaterialBackground(tint: .accentColor)

        let foreground = Text("Action")
            .kikiGlassActionForeground()

        _ = glass
        _ = surface
        _ = background
        _ = foreground
    }

    @Test("Surface defaults expose stable values")
    func surfaceDefaultsExposeStableValues() {
        #expect(KikiSurfaceDefaults.cornerRadius == 12)
        #expect(KikiSurfaceDefaults.tintOpacity == 0.06)
    }

    @MainActor
    @Test("Design color tokens are constructible")
    func designColorTokensAreConstructible() {
        _ = KikiDesignColor.proAccent
        _ = KikiDesignColor.systemAccent
    }

    @MainActor
    @Test("Sheet shell is constructible with and without a footer")
    func sheetShellIsConstructible() {
        let withFooter = KikiSheetShell(
            width: 440,
            minimumHeight: 320,
            idealHeight: 420,
            maximumHeight: 520,
            showsCloseButton: true,
            onClose: {}
        ) {
            Text("Content")
        } footer: {
            Text("Actions")
        }

        let contentOnly = KikiSheetShell(
            width: 440,
            minimumHeight: 320,
            idealHeight: 420,
            maximumHeight: 520
        ) {
            Text("Content")
        }

        _ = withFooter
        _ = contentOnly
    }

    @Test("Application icon resource names support Icon Composer output")
    func applicationIconResourceNamesSupportIconComposerOutput() {
        let implicitExtension = KikiApplicationIcon.resourceLocation(for: "AppIcon")
        #expect(implicitExtension.name == "AppIcon")
        #expect(implicitExtension.extension == "icns")

        let explicitExtension = KikiApplicationIcon.resourceLocation(for: "ProductIcon.icns")
        #expect(explicitExtension.name == "ProductIcon")
        #expect(explicitExtension.extension == "icns")
    }
}
