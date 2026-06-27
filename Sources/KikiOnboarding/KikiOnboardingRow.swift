import SwiftUI

public struct KikiOnboardingRow: Identifiable, Equatable {
    public let id = UUID()
    public let systemImage: String
    public let title: String
    public let detail: String

    public init(
        systemImage: String,
        title: String,
        detail: String
    ) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
    }
}

struct KikiOnboardingRowView: View {
    let row: KikiOnboardingRow
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.systemImage)
                .font(.system(size: 16, weight: .semibold))
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
