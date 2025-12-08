import SwiftUI

struct EditEmployerSheet: View {
    @Binding var name: String
    @Binding var rate: String
    @Binding var active: Bool
    let onSave: () async -> Void
    let onCancel: () -> Void
    @State private var isSaving = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss

    private let localization = EmployersLocalization.shared

    enum Field {
        case name, rate
    }

    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // iOS 26 Style Header
                HStack {
                    // Cancel Button with iOS 26 style
                    Button(action: {
                        onCancel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(localization.editEmployerTitle)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // Save Button with iOS 26 style
                    Button(action: {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .disabled(name.isEmpty || rate.isEmpty || isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))

                ScrollView {
                    VStack(spacing: 20) {
                        // Employer Info Card - iOS 26 Style
                        VStack(spacing: 0) {
                            // Name Row
                            HStack {
                                Text(localization.employerNameSection)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                TextField(localization.employerNamePlaceholder, text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .name)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.horizontal, 16)

                            // Rate Row
                            HStack {
                                Text(localization.hourlyRateSection)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    TextField("15.00", text: $rate)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .rate)
                                        .frame(width: 80)
                                    Text("/hr")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.horizontal, 16)

                            // Active Toggle Row
                            HStack {
                                Text(localization.activeSection)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                CompactLiquidGlassToggle(isOn: $active)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .name
            }
        }
    }

}