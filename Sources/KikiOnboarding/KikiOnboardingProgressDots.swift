import SwiftUI

public struct KikiOnboardingProgressDots: View {
    private let count: Int
    private let currentIndex: Int
    private let tint: Color
    private let dotSize: CGFloat
    private let activeDotWidth: CGFloat
    private let spacing: CGFloat

    public init(
        count: Int,
        currentIndex: Int,
        tint: Color = .accentColor,
        dotSize: CGFloat = 6,
        activeDotWidth: CGFloat = 22,
        spacing: CGFloat = 7
    ) {
        self.count = count
        self.currentIndex = currentIndex
        self.tint = tint
        self.dotSize = dotSize
        self.activeDotWidth = activeDotWidth
        self.spacing = spacing
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? tint : Color.secondary.opacity(0.25))
                    .frame(
                        width: index == currentIndex ? activeDotWidth : dotSize,
                        height: dotSize
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}
