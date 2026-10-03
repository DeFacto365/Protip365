import SwiftUI

struct DetailEmptyState: View {
    let localization: DetailLocalization

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(localization.noDataText)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(localization.noShiftsRecordedText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}