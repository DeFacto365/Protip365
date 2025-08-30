import Foundation
import SwiftUI

class ExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress = 0.0
    
    func exportToCSV(shifts: [ShiftIncome], dateRange: DateRange, language: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // CSV Headers
        let headers = [
            "Date",
            "Start Time",
            "End Time", 
            "Hours",
            "Hourly Rate",
            "Base Salary",
            "Sales",
            "Tips",
            "Tip Out",
            "Total Revenue",
            "Tip Percentage",
            "Employer",
            "Notes"
        ]
        
        var csvContent = headers.joined(separator: ",") + "\n"
        
        // Filter shifts by date range
        let filteredShifts = filterShiftsByDateRange(shifts: shifts, dateRange: dateRange)
        
        for shift in filteredShifts {
            let row = [
                shift.shift_date,
                shift.start_time ?? "",
                shift.end_time ?? "",
                String(format: "%.1f", shift.hours),
                String(format: "%.2f", shift.hourly_rate),
                String(format: "%.2f", shift.hours * shift.hourly_rate),
                String(format: "%.2f", shift.sales),
                String(format: "%.2f", shift.tips),
                String(format: "%.2f", shift.cash_out ?? 0),
                String(format: "%.2f", shift.total_income ?? 0),
                String(format: "%.1f", shift.tip_percentage ?? 0),
                shift.employer_name ?? "",
                shift.notes ?? ""
            ]
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    func exportSummaryToCSV(shifts: [ShiftIncome], dateRange: DateRange, language: String) -> String {
        let filteredShifts = filterShiftsByDateRange(shifts: shifts, dateRange: dateRange)
        
        let totalHours = filteredShifts.reduce(0) { $0 + $1.hours }
        let totalSales = filteredShifts.reduce(0) { $0 + $1.sales }
        let totalTips = filteredShifts.reduce(0) { $0 + $1.tips }
        let totalTipOut = filteredShifts.reduce(0) { $0 + ($1.cash_out ?? 0) }
        let totalRevenue = filteredShifts.reduce(0) { $0 + ($1.total_income ?? 0) }
        let averageTipPercentage = filteredShifts.isEmpty ? 0 : filteredShifts.reduce(0) { $0 + ($1.tip_percentage ?? 0) } / Double(filteredShifts.count)
        
        let summaryHeaders = [
            "Period",
            "Total Shifts",
            "Total Hours",
            "Total Sales",
            "Total Tips", 
            "Total Tip Out",
            "Total Revenue",
            "Average Tip %",
            "Average Hourly Rate"
        ]
        
        var csvContent = summaryHeaders.joined(separator: ",") + "\n"
        
        let summaryRow = [
            dateRange.description,
            String(filteredShifts.count),
            String(format: "%.1f", totalHours),
            String(format: "%.2f", totalSales),
            String(format: "%.2f", totalTips),
            String(format: "%.2f", totalTipOut),
            String(format: "%.2f", totalRevenue),
            String(format: "%.1f", averageTipPercentage),
            String(format: "%.2f", totalHours > 0 ? totalRevenue / totalHours : 0)
        ]
        
        csvContent += summaryRow.joined(separator: ",") + "\n"
        
        return csvContent
    }
    
    private func filterShiftsByDateRange(shifts: [ShiftIncome], dateRange: DateRange) -> [ShiftIncome] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return shifts.filter { shift in
            guard let shiftDate = dateFormatter.date(from: shift.shift_date) else { return false }
            return dateRange.contains(date: shiftDate)
        }
    }
    
    func shareCSVData(shifts: [ShiftIncome], dateRange: DateRange, language: String) -> String {
        let csvContent = exportToCSV(shifts: shifts, dateRange: dateRange, language: language)
        let summaryContent = exportSummaryToCSV(shifts: shifts, dateRange: dateRange, language: language)
        
        return """
        ProTip365 - \(dateRange.description) Report
        
        SUMMARY:
        \(summaryContent)
        
        DETAILED DATA:
        \(csvContent)
        """
    }
}

enum DateRange {
    case week(Date)
    case month(Date)
    case year(Date)
    case custom(Date, Date)
    
    var description: String {
        switch self {
        case .week(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return "Week of \(formatter.string(from: date))"
        case .month(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .year(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
    
    func contains(date: Date) -> Bool {
        switch self {
        case .week(let weekDate):
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: weekDate)?.start ?? weekDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekDate
            return date >= weekStart && date < weekEnd
        case .month(let monthDate):
            let calendar = Calendar.current
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthDate
            return date >= monthStart && date < monthEnd
        case .year(let yearDate):
            let calendar = Calendar.current
            let yearStart = calendar.dateInterval(of: .year, for: yearDate)?.start ?? yearDate
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) ?? yearDate
            return date >= yearStart && date < yearEnd
        case .custom(let start, let end):
            return date >= start && date <= end
        }
    }
}
