import SwiftUI

struct EarningsSection: View {
    // MARK: - Bindings
    @Binding var sales: String
    @Binding var tips: String
    @Binding var tipOut: String
    @Binding var other: String
    @Binding var comments: String

    // MARK: - Parameters
    let salesText: String
    let tipsText: String
    let tipOutText: String
    let otherText: String
    let notesText: String
    let optionalNotesText: String

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Sales Row
            HStack {
                Text(salesText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundStyle(.tint)
                    SelectableTextField(text: $sales, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 8)

            // Tips Row
            HStack {
                Text(tipsText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundStyle(.tint)
                    SelectableTextField(text: $tips, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 8)

            // Tip Out Row
            HStack {
                Text(tipOutText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundStyle(.tint)
                    SelectableTextField(text: $tipOut, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 8)

            // Other Row
            HStack {
                Text(otherText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundStyle(.tint)
                    SelectableTextField(text: $other, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 8)

            // Comments Row
            HStack(alignment: .top) {
                Text(notesText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                TextField(optionalNotesText, text: $comments, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(minWidth: 200)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// Custom TextField that automatically selects all text when tapped
struct SelectableTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)

        // Set placeholder text color to blue
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemBlue]
        )

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SelectableTextField

        init(_ parent: SelectableTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Select all text when the field begins editing
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }
    }
}