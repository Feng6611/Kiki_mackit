import KikiDesign
import SwiftUI

public struct KikiOnboardingLoadingScaffold: View {
    private let appName: String
    private let title: String
    private let bodyText: String?
    private let tint: Color
    private let size: CGSize

    public init(
        appName: String,
        title: String,
        bodyText: String? = nil,
        tint: Color = .accentColor,
        size: CGSize = KikiOnboardingDefaults.windowSize
    ) {
        self.appName = appName
        self.title = title
        self.bodyText = bodyText
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text(title)
                .font(.system(size: 20, weight: .semibold))

            if let bodyText {
                Text(bodyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: size.width, height: size.height)
        .background {
            ZStack {
                KikiMaterialSurface(in: Rectangle(), material: .regularMaterial, tint: tint, tintOpacity: 0.02)
                RadialGradient(
                    colors: [tint.opacity(0.08), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 280
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(appName) onboarding")
    }
}
