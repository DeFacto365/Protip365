import SwiftUI

struct ExportOptionsView: View {
    @ObservedObject var exportManager: ExportManager
    let shifts: [ShiftIncome]
    let language: String

    @Environment(\.dismiss) var dismiss
    @State private var selectedDateRange: DateRange = .week(Date())
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingTimePeriodPicker = false
    @AppStorage("language") private var appLanguage = "en"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(exportDataText)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(chooseTimePeriodText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Date Range Selection with dropdown
                    VStack(spacing: 0) {
                        HStack {
                            Label(timePeriodText, systemImage: "calendar")
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingTimePeriodPicker.toggle()
                                }
                            }) {
                                Text(currentPeriodText)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()

                        if showingTimePeriodPicker {
                            VStack(spacing: 0) {
                                Button(thisWeekText) {
                                    selectedDateRange = .week(Date())
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingTimePeriodPicker = false
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)

                                Divider()

                                Button(thisMonthText) {
                                    selectedDateRange = .month(Date())
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingTimePeriodPicker = false
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)

                                Divider()

                                Button(thisYearText) {
                                    selectedDateRange = .year(Date())
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingTimePeriodPicker = false
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .padding(.horizontal)
                
                    // Export Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text(exportOptionsText)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                            .padding(.top)

                        VStack(spacing: 0) {
                            ExportOptionButton(
                                title: detailedCSVText,
                                subtitle: allShiftDataText,
                                icon: "doc.text",
                                action: exportDetailedCSV
                            )

                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 0.5)
                                .padding(.horizontal)

                            ExportOptionButton(
                                title: summaryCSVText,
                                subtitle: periodTotalsText,
                                icon: "chart.bar",
                                action: exportSummaryCSV
                            )
                        }
                        .padding(.bottom)
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(exportDataText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(cancelText) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    CustomShareSheet(fileURL: url)
                }
            }
        }
    }
    
    private func exportDetailedCSV() {
        let csvContent = exportManager.exportToCSV(shifts: shifts, dateRange: selectedDateRange, language: language)
        let fileName = "ProTip365-\(periodFileName)-Detailed.csv"

        if let url = saveToTempFile(content: csvContent, fileName: fileName) {
            exportURL = url
            showingShareSheet = true
        }
    }

    private func exportSummaryCSV() {
        let csvContent = exportManager.exportSummaryToCSV(shifts: shifts, dateRange: selectedDateRange, language: language)
        let fileName = "ProTip365-\(periodFileName)-Summary.csv"

        if let url = saveToTempFile(content: csvContent, fileName: fileName) {
            exportURL = url
            showingShareSheet = true
        }
    }

    private var periodFileName: String {
        switch selectedDateRange {
        case .week:
            return "ThisWeek"
        case .month:
            return "ThisMonth"
        case .year:
            return "ThisYear"
        case .custom:
            return "Custom"
        }
    }

    private func saveToTempFile(content: String, fileName: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
    
    private var currentPeriodText: String {
        switch selectedDateRange {
        case .week:
            return thisWeekText
        case .month:
            return thisMonthText
        case .year:
            return thisYearText
        case .custom:
            return "Custom"
        }
    }

    // MARK: - Translations

    private var exportDataText: String {
        switch appLanguage {
        case "fr": return "Exporter les données"
        case "es": return "Exportar datos"
        default: return "Export Data"
        }
    }

    private var chooseTimePeriodText: String {
        switch appLanguage {
        case "fr": return "Choisissez une période pour exporter vos données"
        case "es": return "Elija un período para exportar sus datos"
        default: return "Choose a time period to export your data"
        }
    }

    private var timePeriodText: String {
        switch appLanguage {
        case "fr": return "Période"
        case "es": return "Período"
        default: return "Time Period"
        }
    }

    private var thisWeekText: String {
        switch appLanguage {
        case "fr": return "Cette semaine"
        case "es": return "Esta semana"
        default: return "This Week"
        }
    }

    private var last7DaysText: String {
        switch appLanguage {
        case "fr": return "7 derniers jours"
        case "es": return "Últimos 7 días"
        default: return "Last 7 days"
        }
    }

    private var thisMonthText: String {
        switch appLanguage {
        case "fr": return "Ce mois"
        case "es": return "Este mes"
        default: return "This Month"
        }
    }

    private var currentMonthText: String {
        switch appLanguage {
        case "fr": return "Mois actuel"
        case "es": return "Mes actual"
        default: return "Current month"
        }
    }

    private var thisYearText: String {
        switch appLanguage {
        case "fr": return "Cette année"
        case "es": return "Este año"
        default: return "This Year"
        }
    }

    private var currentYearText: String {
        switch appLanguage {
        case "fr": return "Année actuelle"
        case "es": return "Año actual"
        default: return "Current year"
        }
    }

    private var exportOptionsText: String {
        switch appLanguage {
        case "fr": return "Options d'exportation"
        case "es": return "Opciones de exportación"
        default: return "Export Options"
        }
    }

    private var detailedCSVText: String {
        switch appLanguage {
        case "fr": return "CSV détaillé"
        case "es": return "CSV detallado"
        default: return "Detailed CSV"
        }
    }

    private var allShiftDataText: String {
        switch appLanguage {
        case "fr": return "Toutes les données de quarts avec détails"
        case "es": return "Todos los datos de turnos con detalles"
        default: return "All shift data with details"
        }
    }

    private var summaryCSVText: String {
        switch appLanguage {
        case "fr": return "CSV résumé"
        case "es": return "CSV resumen"
        default: return "Summary CSV"
        }
    }

    private var periodTotalsText: String {
        switch appLanguage {
        case "fr": return "Totaux et moyennes de la période"
        case "es": return "Totales y promedios del período"
        default: return "Period totals and averages"
        }
    }

    private var cancelText: String {
        switch appLanguage {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
}


struct ExportOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        // Exclude activities we don't want
        controller.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .print,
            .copyToPasteboard,
            .saveToCameraRoll,
            .markupAsPDF
        ]

        // On iPad, present as popover
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension DateRange {
    var isWeek: Bool {
        if case .week = self { return true }
        return false
    }
    
    var isMonth: Bool {
        if case .month = self { return true }
        return false
    }
    
    var isYear: Bool {
        if case .year = self { return true }
        return false
    }
}
