import SwiftUI

public enum KikiPaywallDefaults {
    public static let sheetWidth: CGFloat = 500
    public static let sheetHeight: CGFloat = 520
    public static let onboardingSheetWidth: CGFloat = 560
    public static let onboardingSheetHeight: CGFloat = 620
    public static let sheetPadding: CGFloat = 28
}

public struct KikiPaywallPlan: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let displayPrice: String
    public let originalPrice: String?
    public let billingDetail: String
    public let badge: String?
    public let isAvailable: Bool

    public init(
        id: String,
        title: String,
        displayPrice: String,
        originalPrice: String? = nil,
        billingDetail: String,
        badge: String? = nil,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.displayPrice = displayPrice
        self.originalPrice = originalPrice
        self.billingDetail = billingDetail
        self.badge = badge
        self.isAvailable = isAvailable
    }
}

public struct KikiPaywallShell<Header: View, Content: View, Actions: View, Footer: View>: View {
    private let width: CGFloat
    private let height: CGFloat
    private let horizontalPadding: CGFloat
    private let tint: Color
    private let showsCloseButton: Bool
    private let onClose: (() -> Void)?
    private let header: Header
    private let content: Content
    private let actions: Actions
    private let footer: Footer

    public init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        height: CGFloat = KikiPaywallDefaults.sheetHeight,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder footer: () -> Footer
    ) {
        self.width = width
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.tint = tint
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.header = header()
        self.content = content()
        self.actions = actions()
        self.footer = footer()
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header
                            .padding(.top, 8)
                        content
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 14)
                }

                VStack(spacing: 8) {
                    actions
                    footer
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 14)
            }

            if showsCloseButton {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(20)
                .accessibilityLabel("Close")
            }
        }
        .frame(width: width, height: height)
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                RadialGradient(
                    colors: [tint.opacity(0.05), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 350
                )
            }
        }
    }
}

public extension KikiPaywallShell where Actions == EmptyView, Footer == EmptyView {
    init(
        width: CGFloat = KikiPaywallDefaults.sheetWidth,
        height: CGFloat = KikiPaywallDefaults.sheetHeight,
        horizontalPadding: CGFloat = KikiPaywallDefaults.sheetPadding,
        tint: Color = .accentColor,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            width: width,
            height: height,
            horizontalPadding: horizontalPadding,
            tint: tint,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            header: header,
            content: content,
            actions: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

public struct KikiPaywallHeader: View {
    private let title: String
    private let subtitle: String
    private let icon: NSImage
    private let iconSize: CGFloat

    public init(
        title: String,
        subtitle: String,
        icon: NSImage = NSApp.applicationIconImage,
        iconSize: CGFloat = 80
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconSize = iconSize
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.10), radius: 10, y: 5)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

public struct KikiPaywallStatItem: View {
    private let value: String
    private let label: String
    private let tint: Color

    public init(value: String, label: String, tint: Color = .accentColor) {
        self.value = value
        self.label = label
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

public struct KikiPaywallFeatureRow: View {
    private let icon: String
    private let text: String
    private let tint: Color

    public init(icon: String, text: String, tint: Color = .accentColor) {
        self.icon = icon
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

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
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(tint))
                } else {
                    Text(plan.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let originalPrice = plan.originalPrice {
                        Text(originalPrice)
                            .font(.callout)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Text(plan.displayPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.06) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? tint : Color(nsColor: .separatorColor).opacity(0.4),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!plan.isAvailable)
        .opacity(plan.isAvailable ? 1 : 0.45)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

public struct KikiPaywallActionLabel: View {
    private let title: String
    private let isLoading: Bool
    private let isProminent: Bool
    private let tint: Color

    public init(
        title: String,
        isLoading: Bool,
        isProminent: Bool,
        tint: Color = .accentColor
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isProminent = isProminent
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Text(title)
                .font(.headline)
        }
        .foregroundStyle(isProminent ? .white : .primary)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isProminent ? tint : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isProminent ? Color.clear : Color(nsColor: .separatorColor).opacity(0.4),
                    lineWidth: 0.5
                )
        )
    }
}
