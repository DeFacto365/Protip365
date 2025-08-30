import SwiftUI

struct ExportOptionsView: View {
    @ObservedObject var exportManager: ExportManager
    let shifts: [ShiftIncome]
    let language: String
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedDateRange: DateRange = .week(Date())
    @State private var showingShareSheet = false
    @State private var exportData = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Export Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose a time period to export your data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Date Range Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Period")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        DateRangeButton(
                            title: "This Week",
                            subtitle: "Last 7 days",
                            isSelected: selectedDateRange.isWeek,
                            action: { selectedDateRange = .week(Date()) }
                        )
                        
                        DateRangeButton(
                            title: "This Month",
                            subtitle: "Current month",
                            isSelected: selectedDateRange.isMonth,
                            action: { selectedDateRange = .month(Date()) }
                        )
                        
                        DateRangeButton(
                            title: "This Year",
                            subtitle: "Current year",
                            isSelected: selectedDateRange.isYear,
                            action: { selectedDateRange = .year(Date()) }
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Export Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Options")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        ExportOptionButton(
                            title: "Detailed CSV",
                            subtitle: "All shift data with details",
                            icon: "doc.text",
                            action: exportDetailedCSV
                        )
                        
                        ExportOptionButton(
                            title: "Summary CSV",
                            subtitle: "Period totals and averages",
                            icon: "chart.bar",
                            action: exportSummaryCSV
                        )
                        
                        ExportOptionButton(
                            title: "Share Summary",
                            subtitle: "Share formatted summary",
                            icon: "square.and.arrow.up",
                            action: shareSummary
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [exportData])
            }
        }
    }
    
    private func exportDetailedCSV() {
        exportData = exportManager.exportToCSV(shifts: shifts, dateRange: selectedDateRange, language: language)
        showingShareSheet = true
    }
    
    private func exportSummaryCSV() {
        exportData = exportManager.exportSummaryToCSV(shifts: shifts, dateRange: selectedDateRange, language: language)
        showingShareSheet = true
    }
    
    private func shareSummary() {
        exportData = exportManager.shareCSVData(shifts: shifts, dateRange: selectedDateRange, language: language)
        showingShareSheet = true
    }
}

struct DateRangeButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
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
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
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
