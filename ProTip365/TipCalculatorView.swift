import SwiftUI

struct TipCalculatorView: View {
    @State private var billAmount = ""
    @State private var tipPercentage = 15.0
    @State private var numberOfPeople = 1
    @AppStorage("language") private var language = "en"

    var tipAmount: Double {
        let bill = Double(billAmount) ?? 0
        return bill * (tipPercentage / 100)
    }

    var totalAmount: Double {
        let bill = Double(billAmount) ?? 0
        return bill + tipAmount
    }

    var amountPerPerson: Double {
        totalAmount / Double(numberOfPeople)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Standard gray background used across all pages
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Single unified card for all calculator elements
                    VStack(spacing: 0) {
                        // Bill Amount Section
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "receipt")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(billSection)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            HStack {
                                Text(getCurrencySymbol())
                                    .font(.system(size: 20))
                                    .fontWeight(.light)
                                    .foregroundStyle(.secondary)

                                TextField("0.00", text: $billAmount)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: billAmount) { _, newValue in
                                        // Limit to 2 decimal places
                                        if let dotIndex = newValue.firstIndex(of: ".") {
                                            let afterDot = newValue[newValue.index(after: dotIndex)...]
                                            if afterDot.count > 2 {
                                                billAmount = String(newValue.prefix(newValue.count - 1))
                                            }
                                        }
                                    }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }

                        Divider()
                            .padding(.horizontal, 16)

                        // Tip Percentage Section
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "percent")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(tipSection)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(tipPercentage))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                            // Quick Tip Buttons
                            HStack(spacing: 6) {
                                ForEach([10, 15, 18, 20, 30], id: \.self) { percentage in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            tipPercentage = Double(percentage)
                                        }
                                        HapticFeedback.light()
                                    }) {
                                        Text("\(percentage)%")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 6)
                                            .background(
                                                tipPercentage == Double(percentage) ?
                                                    Color.blue :
                                                    Color(.systemGray6)
                                            )
                                            .foregroundColor(tipPercentage == Double(percentage) ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            // Slider
                            VStack(spacing: 2) {
                                Slider(value: $tipPercentage, in: 0...30, step: 1)
                                    .tint(.blue)
                                    .onChange(of: tipPercentage) { _, _ in
                                        HapticFeedback.selection()
                                    }

                                HStack {
                                    Text("0%")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                    Text("30%")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }

                        Divider()
                            .padding(.horizontal, 16)

                        // Split Section
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(splitSection)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 10) {
                                Button(action: {
                                    if numberOfPeople > 1 {
                                        numberOfPeople -= 1
                                        HapticFeedback.light()
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(numberOfPeople > 1 ? .blue : .gray)
                                }
                                .disabled(numberOfPeople <= 1)

                                Text("\(numberOfPeople)")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .frame(width: 26)

                                Button(action: {
                                    if numberOfPeople < 20 {
                                        numberOfPeople += 1
                                        HapticFeedback.light()
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(numberOfPeople < 20 ? .blue : .gray)
                                }
                                .disabled(numberOfPeople >= 20)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()
                            .padding(.horizontal, 16)

                        // Results Section
                        VStack(spacing: 8) {
                            // Tip Amount
                            HStack {
                                Text(tipAmountLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatCurrency(tipAmount))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                            // Total
                            HStack {
                                Text(totalLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(formatCurrency(totalAmount))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 16)

                            if numberOfPeople > 1 {
                                // Per Person
                                HStack {
                                    Text(perPersonLabel)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(formatCurrency(amountPerPerson))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, 16)
                            }

                            // Add bottom padding
                            Color.clear.frame(height: 8)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle(calculatorTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func getCurrencySymbol() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.currencySymbol ?? "$"
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    // Localization
    var calculatorTitle: String {
        switch language {
        case "fr": return "Calculatrice"
        case "es": return "Calculadora"
        default: return "Tip Calculator"
        }
    }

    var billSection: String {
        switch language {
        case "fr": return "Montant"
        case "es": return "Cuenta"
        default: return "Bill Amount"
        }
    }

    var tipSection: String {
        switch language {
        case "fr": return "Pourboire"
        case "es": return "Propina"
        default: return "Tip"
        }
    }

    var splitSection: String {
        switch language {
        case "fr": return "Diviser"
        case "es": return "Dividir"
        default: return "Split"
        }
    }

    var personText: String {
        switch language {
        case "fr": return "personne"
        case "es": return "persona"
        default: return "person"
        }
    }

    var peopleText: String {
        switch language {
        case "fr": return "personnes"
        case "es": return "personas"
        default: return "people"
        }
    }

    var tipAmountLabel: String {
        switch language {
        case "fr": return "Pourboire"
        case "es": return "Propina"
        default: return "Tip Amount"
        }
    }

    var totalLabel: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }

    var perPersonLabel: String {
        switch language {
        case "fr": return "Par personne"
        case "es": return "Por persona"
        default: return "Per Person"
        }
    }
}

