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
            Form {
                Section(billSection) {
                    TextField(billPlaceholder, text: $billAmount)
                        .keyboardType(.decimalPad)
                }
                
                Section(tipSection) {
                    HStack {
                        Text(tipPercentageLabel)
                        Spacer()
                        Text("\(tipPercentage, specifier: "%.0f")%")
                            .fontWeight(.semibold)
                    }
                    
                    Slider(value: $tipPercentage, in: 0...30, step: 1)
                    
                    HStack(spacing: 12) {
                        ForEach([10, 15, 18, 20], id: \.self) { percentage in
                            Button(action: {
                                tipPercentage = Double(percentage)
                            }) {
                                Text("\(percentage)%")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(tipPercentage == Double(percentage) ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(tipPercentage == Double(percentage) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section(splitSection) {
                    Stepper(value: $numberOfPeople, in: 1...20) {
                        HStack {
                            Text(peopleLabel)
                            Spacer()
                            Text("\(numberOfPeople)")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section(resultsSection) {
                    HStack {
                        Text(tipAmountLabel)
                        Spacer()
                        Text("$\(tipAmount, specifier: "%.2f")")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text(totalLabel)
                        Spacer()
                        Text("$\(totalAmount, specifier: "%.2f")")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    if numberOfPeople > 1 {
                        HStack {
                            Text(perPersonLabel)
                            Spacer()
                            Text("$\(amountPerPerson, specifier: "%.2f")")
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .navigationTitle(calculatorTitle)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button(doneButton) {
                            hideKeyboard()
                        }
                    }
                }
            }
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        case "fr": return "Montant de la facture"
        case "es": return "Monto de la cuenta"
        default: return "Bill Amount"
        }
    }
    
    var billPlaceholder: String {
        switch language {
        case "fr": return "Entrez le montant"
        case "es": return "Ingrese el monto"
        default: return "Enter amount"
        }
    }
    
    var tipSection: String {
        switch language {
        case "fr": return "Pourboire"
        case "es": return "Propina"
        default: return "Tip"
        }
    }
    
    var tipPercentageLabel: String {
        switch language {
        case "fr": return "Pourcentage"
        case "es": return "Porcentaje"
        default: return "Percentage"
        }
    }
    
    var splitSection: String {
        switch language {
        case "fr": return "Diviser la facture"
        case "es": return "Dividir la cuenta"
        default: return "Split Bill"
        }
    }
    
    var peopleLabel: String {
        switch language {
        case "fr": return "Nombre de personnes"
        case "es": return "Número de personas"
        default: return "Number of people"
        }
    }
    
    var resultsSection: String {
        switch language {
        case "fr": return "Résultats"
        case "es": return "Resultados"
        default: return "Results"
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
    
    var doneButton: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Listo"
        default: return "Done"
        }
    }
}
