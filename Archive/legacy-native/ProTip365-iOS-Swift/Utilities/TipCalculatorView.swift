import SwiftUI

struct TipCalculatorView: View {
    @State private var selectedTab = 1  // Default to Tip-Out tab
    @AppStorage("language") private var language = "en"
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Standard gray background used across all pages
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab Picker
                    Picker("Calculator Type", selection: $selectedTab) {
                        Text(tipCalculatorTab)
                            .tag(0)
                        Text(tipOutTab)
                            .tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Content based on selected tab
                    if selectedTab == 0 {
                        TipCalculatorContent(language: language, horizontalSizeClass: horizontalSizeClass)
                    } else {
                        TipOutCalculatorContent(language: language, horizontalSizeClass: horizontalSizeClass)
                    }
                }
            }
            .navigationTitle(calculatorTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Localization
    var calculatorTitle: String {
        switch language {
        case "fr": return "Calculatrice"
        case "es": return "Calculadora"
        default: return "Calculator"
        }
    }

    var tipCalculatorTab: String {
        switch language {
        case "fr": return "Calculateur de Pourboire"
        case "es": return "Calculadora de Propinas"
        default: return "Tip Calculator"
        }
    }

    var tipOutTab: String {
        switch language {
        case "fr": return "Partage de Pourboires"
        case "es": return "Distribución de Propinas"
        default: return "Tip-out"
        }
    }
}

struct TipCalculatorContent: View {
    @State private var billAmount = ""
    @State private var tipPercentage = 15.0
    @State private var numberOfPeople = 1
    @FocusState private var isTextFieldFocused: Bool
    let language: String
    let horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.colorScheme) private var colorScheme
    
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
        ScrollView {
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
                                .focused($isTextFieldFocused)
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
                        .background(Color(.secondarySystemGroupedBackground))
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
                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)

                Spacer(minLength: 0)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside the text field
            isTextFieldFocused = false
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

struct TipOutCalculatorContent: View {
    @State private var totalTips = ""
    @State private var barPercentage = "5"
    @State private var busserPercentage = "3"
    @State private var runnerPercentage = "2"
    @FocusState private var isTextFieldFocused: Bool
    let language: String
    let horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.colorScheme) private var colorScheme

    var tips: Double {
        Double(totalTips) ?? 0.0
    }

    var barAmount: Double {
        let percentage = Double(barPercentage) ?? 0.0
        return tips * (percentage / 100)
    }

    var busserAmount: Double {
        let percentage = Double(busserPercentage) ?? 0.0
        return tips * (percentage / 100)
    }

    var runnerAmount: Double {
        let percentage = Double(runnerPercentage) ?? 0.0
        return tips * (percentage / 100)
    }

    var totalTipOut: Double {
        barAmount + busserAmount + runnerAmount
    }

    var keepAmount: Double {
        tips - totalTipOut
    }

    var keepPercentage: Double {
        guard tips > 0 else { return 0 }
        return (keepAmount / tips) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Main card
                VStack(spacing: 0) {
                    // Total Tips Section
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(totalTipsSection)
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

                            TextField("0.00", text: $totalTips)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                                .keyboardType(.decimalPad)
                                .focused($isTextFieldFocused)
                                .onChange(of: totalTips) { _, newValue in
                                    // Limit to 2 decimal places
                                    if let dotIndex = newValue.firstIndex(of: ".") {
                                        let afterDot = newValue[newValue.index(after: dotIndex)...]
                                        if afterDot.count > 2 {
                                            totalTips = String(newValue.prefix(newValue.count - 1))
                                        }
                                    }
                                }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    Divider()
                        .padding(.horizontal, 16)

                    // Tip-out Distribution Section
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "person.3")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(tipOutDistribution)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            // Helper text explaining the percentages
                            Text(tipOutExplanation)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // Bar
                        TipOutFieldView(
                            label: barLabel,
                            percentage: $barPercentage,
                            amount: barAmount,
                            language: language
                        )
                        .padding(.horizontal, 16)

                        // Busser
                        TipOutFieldView(
                            label: busserLabel,
                            percentage: $busserPercentage,
                            amount: busserAmount,
                            language: language
                        )
                        .padding(.horizontal, 16)

                        // Runner
                        TipOutFieldView(
                            label: runnerLabel,
                            percentage: $runnerPercentage,
                            amount: runnerAmount,
                            language: language
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    Divider()
                        .padding(.horizontal, 16)

                    // Results Section
                    VStack(spacing: 8) {
                        // Total Tip-out
                        HStack {
                            Text(totalTipOutLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatCurrency(totalTipOut))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // You Keep
                        HStack {
                            Text(youKeepLabel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(formatCurrency(keepAmount))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 16)

                        // Percentage kept
                        if tips > 0 {
                            HStack {
                                Spacer()
                                Text(String(format: youKeepPercentageText, keepPercentage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }

                        // Add bottom padding
                        Color.clear.frame(height: 8)
                    }
                    .padding(.bottom, 8)
                }
                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)

                Spacer(minLength: 0)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside the text field
            isTextFieldFocused = false
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
    var totalTipsSection: String {
        switch language {
        case "fr": return "Pourboires Totaux"
        case "es": return "Propinas Totales"
        default: return "Total Tips"
        }
    }

    var tipOutDistribution: String {
        switch language {
        case "fr": return "Distribution des Pourboires"
        case "es": return "Distribución de Propinas"
        default: return "Tip-out Distribution"
        }
    }

    var barLabel: String {
        switch language {
        case "fr": return "Bar"
        case "es": return "Bar"
        default: return "Bar"
        }
    }

    var busserLabel: String {
        switch language {
        case "fr": return "Aide-serveur"
        case "es": return "Ayudante"
        default: return "Busser"
        }
    }

    var runnerLabel: String {
        switch language {
        case "fr": return "Coureur"
        case "es": return "Corredor"
        default: return "Runner"
        }
    }

    var totalTipOutLabel: String {
        switch language {
        case "fr": return "Total à Distribuer"
        case "es": return "Total a Distribuir"
        default: return "Total Tip-out"
        }
    }

    var youKeepLabel: String {
        switch language {
        case "fr": return "Vous Gardez"
        case "es": return "Te Quedas"
        default: return "You Keep"
        }
    }

    var youKeepPercentageText: String {
        switch language {
        case "fr": return "Vous gardez %.1f%% de vos pourboires"
        case "es": return "Te quedas con el %.1f%% de tus propinas"
        default: return "You keep %.1f%% of your tips"
        }
    }

    var tipOutExplanation: String {
        switch language {
        case "fr": return "Entrez le % de vos pourboires à distribuer à chaque rôle"
        case "es": return "Ingresa el % de tus propinas para distribuir a cada rol"
        default: return "Enter % of your tips to distribute to each role"
        }
    }
}

struct TipOutFieldView: View {
    let label: String
    @Binding var percentage: String
    let amount: Double
    let language: String

    var body: some View {
        HStack(spacing: 12) {
            // Label and percentage input
            HStack(spacing: 8) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(width: 80, alignment: .leading)

                TextField("0", text: $percentage)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .multilineTextAlignment(.trailing)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onChange(of: percentage) { _, newValue in
                        // Limit to numbers only and max 2 digits
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 2 {
                            percentage = String(filtered.prefix(2))
                        } else {
                            percentage = filtered
                        }
                    }

                Text("%")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            Text(formatCurrency(amount))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
