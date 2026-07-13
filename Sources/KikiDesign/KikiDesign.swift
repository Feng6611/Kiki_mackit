import AppKit
import SwiftUI

public enum KikiSurfaceDefaults {
    public static let cornerRadius: CGFloat = 12
    public static let tintOpacity: Double = 0.06
}

public enum KikiDesignColor {
    public static let brandAccent = Color(red: 0.58, green: 0.20, blue: 0.62)
    public static var systemAccent: Color {
        Color(nsColor: .controlAccentColor)
    }

    public static let brand_accent = brandAccent
    public static var system_accent: Color {
        systemAccent
    }
}

/// Resolves the icon emitted into the host app bundle before falling back to
/// AppKit's process-wide application icon.
public enum KikiApplicationIcon {
    public static var current: NSImage {
        let bundle = Bundle.main

        for key in ["CFBundleIconFile", "CFBundleIconName"] {
            guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
                continue
            }

            let location = resourceLocation(for: value)
            guard
                let url = bundle.url(
                    forResource: location.name,
                    withExtension: location.extension
                ),
                let image = NSImage(contentsOf: url) else {
                continue
            }

            return image
        }

        return NSApp.applicationIconImage
    }

    static func resourceLocation(for iconValue: String) -> (name: String, extension: String) {
        let path = iconValue as NSString
        let pathExtension = path.pathExtension

        if pathExtension.isEmpty {
            return (iconValue, "icns")
        }

        return (path.deletingPathExtension, pathExtension)
    }
}

public struct KikiMaterialSurface<S: Shape>: View {
    private let shape: S
    private let material: Material
    private let tint: Color
    private let tintOpacity: Double

    public init(
        in shape: S,
        material: Material = .regularMaterial,
        tint: Color = .clear,
        tintOpacity: Double = KikiSurfaceDefaults.tintOpacity
    ) {
        self.shape = shape
        self.material = material
        self.tint = tint
        self.tintOpacity = tintOpacity
    }

    public var body: some View {
        shape
            .fill(material)
            .overlay {
                shape.fill(tint.opacity(tintOpacity))
            }
    }
}

public extension View {
    @ViewBuilder
    func kikiAdaptiveGlass<S: Shape>(in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    func kikiMaterialSurface<S: Shape>(
        in shape: S,
        material: Material = .regularMaterial,
        tint: Color = .clear,
        tintOpacity: Double = KikiSurfaceDefaults.tintOpacity
    ) -> some View {
        background {
            KikiMaterialSurface(
                in: shape,
                material: material,
                tint: tint,
                tintOpacity: tintOpacity
            )
        }
    }

    func kikiWindowMaterialBackground(
        material: Material = .regularMaterial,
        tint: Color = .clear,
        tintOpacity: Double = KikiSurfaceDefaults.tintOpacity
    ) -> some View {
        background {
            ZStack {
                Rectangle().fill(material)
                Rectangle().fill(tint.opacity(tintOpacity))
            }
        }
    }

    @ViewBuilder
    func kikiGlassActionForeground() -> some View {
        if #available(macOS 26.0, *) {
            self.foregroundStyle(.white)
        } else {
            self.foregroundStyle(.primary)
        }
    }
}
