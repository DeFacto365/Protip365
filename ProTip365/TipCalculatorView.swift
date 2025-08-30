import SwiftUI

struct TipCalculatorView: View {
    @State private var billAmount = ""
    @State private var tipPercentage = 15.0
    @State private var numberOfPeople = 1
    @State private var isShowingNumberPad = false
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
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Helpful explanation
                        VStack(spacing: 8) {
                            Text("💡 Quick tip calculator")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Enter your bill amount and adjust tip percentage. Split the total between multiple people if needed.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Bill Amount Input Card - MORE COMPACT
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "receipt")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text(billSection)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            // Bill Amount Display - SMALLER SIZE
                            Button(action: {
                                isShowingNumberPad.toggle()
                                HapticFeedback.light()
                            }) {
                                HStack {
                                    Text(getCurrencySymbol())
                                        .font(.title)
                                        .fontWeight(.light)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(billAmount.isEmpty ? "0.00" : billAmount)
                                        .font(.system(size: 36, weight: .medium, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Tip Percentage Card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "percent")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text(tipSection)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(tipPercentage))%")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            
                            // Quick Tip Buttons - CHANGED TO 30%
                            HStack(spacing: 10) {
                                ForEach([10, 15, 18, 20, 30], id: \.self) { percentage in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            tipPercentage = Double(percentage)
                                        }
                                        HapticFeedback.light()
                                    }) {
                                        Text("\(percentage)%")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                tipPercentage == Double(percentage) ?
                                                    AnyShapeStyle(Color.blue) :
                                                    AnyShapeStyle(.regularMaterial)
                                            )
                                            .foregroundColor(tipPercentage == Double(percentage) ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(.white.opacity(0.2), lineWidth: tipPercentage == Double(percentage) ? 0 : 1)
                                            )
                                    }
                                }
                            }
                            
                            // Custom Slider
                            VStack(spacing: 6) {
                                Slider(value: $tipPercentage, in: 0...30, step: 1)
                                    .tint(.blue)
                                    .onChange(of: tipPercentage) { _, _ in
                                        HapticFeedback.selection()
                                    }
                                
                                HStack {
                                    Text("0%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("30%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Split Bill Card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.2")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text(splitSection)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    if numberOfPeople > 1 {
                                        numberOfPeople -= 1
                                        HapticFeedback.light()
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(numberOfPeople > 1 ? .blue : .gray)
                                }
                                .disabled(numberOfPeople <= 1)
                                
                                VStack(spacing: 4) {
                                    Text("\(numberOfPeople)")
                                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    Text(numberOfPeople == 1 ? personText : peopleText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 100)
                                
                                Button(action: {
                                    if numberOfPeople < 20 {
                                        numberOfPeople += 1
                                        HapticFeedback.light()
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(numberOfPeople < 20 ? .blue : .gray)
                                }
                                .disabled(numberOfPeople >= 20)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Results Card
                        VStack(spacing: 0) {
                            // Tip Amount
                            ResultRow(
                                label: tipAmountLabel,
                                amount: tipAmount,
                                color: .blue,
                                isHighlighted: false
                            )
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // Total
                            ResultRow(
                                label: totalLabel,
                                amount: totalAmount,
                                color: .green,
                                isHighlighted: true
                            )
                            
                            if numberOfPeople > 1 {
                                Divider()
                                    .padding(.horizontal)
                                
                                // Per Person
                                ResultRow(
                                    label: perPersonLabel,
                                    amount: amountPerPerson,
                                    color: .purple,
                                    isHighlighted: true
                                )
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle(calculatorTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isShowingNumberPad) {
                NumberPadView(amount: $billAmount, isPresented: $isShowingNumberPad)
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    func getCurrencySymbol() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.currencySymbol ?? "$"
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

// MARK: - Components

struct ResultRow: View {
    let label: String
    let amount: Double
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(isHighlighted ? .headline : .subheadline)
                .foregroundStyle(isHighlighted ? .primary : .secondary)
            
            Spacer()
            
            Text(formatCurrency(amount))
                .font(isHighlighted ? .title2 : .title3)
                .fontWeight(isHighlighted ? .bold : .semibold)
                .foregroundStyle(color)
        }
        .padding()
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct NumberPadView: View {
    @Binding var amount: String
    @Binding var isPresented: Bool
    
    let buttons = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Display
            HStack {
                Text("$")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(amount.isEmpty ? "0.00" : amount)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Number Pad
            VStack(spacing: 12) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                handleButtonTap(button)
                            }) {
                                Text(button)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
            
            // Done Button
            Button(action: {
                isPresented = false
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
    }
    
    func handleButtonTap(_ button: String) {
        HapticFeedback.light()
        
        switch button {
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case ".":
            if !amount.contains(".") {
                amount += button
            }
        default:
            // Limit to 2 decimal places
            if let dotIndex = amount.firstIndex(of: ".") {
                let afterDot = amount[amount.index(after: dotIndex)...]
                if afterDot.count < 2 {
                    amount += button
                }
            } else {
                amount += button
            }
        }
    }
}
