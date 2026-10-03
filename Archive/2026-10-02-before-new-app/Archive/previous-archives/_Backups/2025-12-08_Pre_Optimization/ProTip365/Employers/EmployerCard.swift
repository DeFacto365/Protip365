import SwiftUI

struct EmployerCard: View {
    let employer: Employer
    let shiftCount: Int
    let entryCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let localization = EmployersLocalization.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(employer.name)
                        .font(.headline)
                        .foregroundColor(employer.active ? .primary : .secondary)
                        .strikethrough(!employer.active)

                    if !employer.active {
                        Text("(\(localization.inactiveLabel))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(employer.active ? .green : .gray)
                    Text("$\(employer.hourly_rate, specifier: "%.2f")/hr")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(employer.active ? .secondary : Color(.tertiaryLabel))
                }

                // Display both shifts and entries counts
                VStack(alignment: .leading, spacing: 2) {
                    // Always show shifts count
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(localization.shiftsCountLabel) \(shiftCount == 1 ? localization.shiftsCountSingular : String(format: localization.shiftsCountPlural, shiftCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Always show entries count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(entryCount > 0 ? .green : .gray)
                        Text("\(localization.entriesCountLabel) \(entryCount == 1 ? localization.entriesCountSingular : String(format: localization.entriesCountPlural, entryCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    HapticFeedback.light()
                    onEdit()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                }

                Button(action: {
                    HapticFeedback.light()
                    onDelete()
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle((shiftCount > 0 || entryCount > 0) ? .gray : .red)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(shiftCount > 0 || entryCount > 0)
                .opacity((shiftCount > 0 || entryCount > 0) ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(employer.active ? Color(.systemBackground) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(employer.active ? 0.05 : 0.02), radius: 2, x: 0, y: 1)
    }

}