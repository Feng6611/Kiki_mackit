import SwiftUI

public struct KikiOnboardingRow: Identifiable, Equatable {
    public let id: UUID
    public let systemImage: String
    public let title: String
    public let detail: String

    public init(
        id: UUID? = nil,
        systemImage: String,
        title: String,
        detail: String
    ) {
        self.id = id ?? kikiOnboardingStableUUID(
            for: "\(systemImage)\u{1F}\(title)\u{1F}\(detail)"
        )
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
    }
}

private func kikiOnboardingStableUUID(for value: String) -> UUID {
    var high: UInt64 = 0xcbf29ce484222325
    var low: UInt64 = 0x84222325cbf29ce4

    for byte in value.utf8 {
        high = (high ^ UInt64(byte)) &* 0x100000001b3
        low = (low ^ UInt64(byte)) &* 0x9e3779b185ebca87
    }

    return UUID(uuid: (
        UInt8(truncatingIfNeeded: high >> 56),
        UInt8(truncatingIfNeeded: high >> 48),
        UInt8(truncatingIfNeeded: high >> 40),
        UInt8(truncatingIfNeeded: high >> 32),
        UInt8(truncatingIfNeeded: high >> 24),
        UInt8(truncatingIfNeeded: high >> 16),
        UInt8(truncatingIfNeeded: high >> 8),
        UInt8(truncatingIfNeeded: high),
        UInt8(truncatingIfNeeded: low >> 56),
        UInt8(truncatingIfNeeded: low >> 48),
        UInt8(truncatingIfNeeded: low >> 40),
        UInt8(truncatingIfNeeded: low >> 32),
        UInt8(truncatingIfNeeded: low >> 24),
        UInt8(truncatingIfNeeded: low >> 16),
        UInt8(truncatingIfNeeded: low >> 8),
        UInt8(truncatingIfNeeded: low)
    ))
}

struct KikiOnboardingRowView: View {
    let row: KikiOnboardingRow
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(.headline)

                Text(row.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
