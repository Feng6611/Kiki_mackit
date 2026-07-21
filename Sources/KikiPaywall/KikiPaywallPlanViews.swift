import AppKit
import KikiDesign
import SwiftUI

public struct KikiPaywallPlanCard: View {
    private let plan: KikiPaywallPlan
    private let isSelected: Bool
    private let tint: Color
    private let onSelect: () -> Void

    public init(
        plan: KikiPaywallPlan,
        isSelected: Bool,
        tint: Color = .accentColor,
        onSelect: @escaping () -> Void
    ) {
        self.plan = plan
        self.isSelected = isSelected
        self.tint = tint
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                if let badge = plan.badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(tint.opacity(KikiDesignTokens.Opacity.strongFill)))
                }

                Text(plan.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let originalPrice = plan.originalPrice {
                        Text(originalPrice)
                            .font(.callout)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Text(plan.displayPrice)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }

                Text(plan.billingDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .fill(isSelected ? tint.opacity(KikiDesignTokens.Opacity.subtleFill) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? tint : Color(nsColor: .separatorColor).opacity(KikiDesignTokens.Separator.mutedOpacity),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!plan.isAvailable)
        .opacity(plan.isAvailable ? 1 : KikiDesignTokens.Opacity.disabledContent)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plan.title), \(plan.displayPrice), \(plan.billingDetail)")
        .accessibilityValue(isSelected
            ? String(localized: "Selected", bundle: .main, comment: "VoiceOver value for a selected paywall plan card.")
            : String(localized: "Not selected", bundle: .main, comment: "VoiceOver value for an unselected paywall plan card."))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct KikiPaywallPlanRow: View {
    private let plan: KikiPaywallPlan
    private let isSelected: Bool
    private let tint: Color
    private let priceSuffix: String?
    private let showsUnavailablePill: Bool
    private let isDisabled: Bool
    private let onSelect: () -> Void

    public init(
        plan: KikiPaywallPlan,
        isSelected: Bool,
        tint: Color = .accentColor,
        priceSuffix: String? = nil,
        showsUnavailablePill: Bool = true,
        isDisabled: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.plan = plan
        self.isSelected = isSelected
        self.tint = tint
        self.priceSuffix = priceSuffix
        self.showsUnavailablePill = showsUnavailablePill
        self.isDisabled = isDisabled
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                selectionIndicator

                HStack(spacing: 6) {
                    Text(plan.title)
                        .font(.callout.weight(.medium))

                    if let badge = plan.badge {
                        KikiPaywallPill(text: badge, tone: .accent, tint: tint)
                    }

                    if showsUnavailablePill, !plan.isAvailable {
                        KikiPaywallPill(text: "Unavailable", tone: .neutral, tint: tint)
                    }
                }

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let originalPrice = plan.originalPrice {
                        Text(originalPrice)
                            .font(.callout)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }

                    Text(plan.displayPrice)
                        .font(.headline)
                        .foregroundStyle(isSelected ? tint : .primary)

                    if let priceSuffix {
                        Text(priceSuffix)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .fill(isSelected ? tint.opacity(KikiDesignTokens.Opacity.subtleFill) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: KikiDesignTokens.CornerRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? tint.opacity(KikiDesignTokens.Opacity.selectedStrokeOpacity) : Color(nsColor: .separatorColor).opacity(KikiDesignTokens.Separator.mutedOpacity),
                        lineWidth: isSelected ? 1.25 : 0.75
                    )
            )
            .opacity(plan.isAvailable ? 1 : KikiDesignTokens.Opacity.disabledContent)
        }
        .buttonStyle(.plain)
        .disabled(!plan.isAvailable || isDisabled)
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? tint : Color(nsColor: .separatorColor),
                    lineWidth: 1.5
                )
                .frame(width: 18, height: 18)

            if isSelected {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
