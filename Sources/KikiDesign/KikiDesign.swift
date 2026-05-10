import SwiftUI

public enum KikiSurfaceDefaults {
    public static let cornerRadius: CGFloat = 12
    public static let tintOpacity: Double = 0.06
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
