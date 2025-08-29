import SwiftUI
import Supabase

struct DashboardView: View {
    @State private var todayStats = Stats()
    @State private var weekStats = Stats()
    @State private var monthStats = Stats()
    @State private var selectedPeriod = 0
    @AppStorage("language") private var language = "en"
    
    struct Stats {
        var hours: Double = 0
        var sales: Double = 0
        var tips: Double = 0
        var income: Double = 0
        var tipPercentage: Double = 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        Text(todayText).tag(0)
                        Text(weekText).tag(1)
                        Text(monthText).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Stats Cards
                    VStack(spacing: 16) {
                        // Total Income Card
                        StatCard(
                            title: totalIncomeText,
                            value: String(format: "$%.2f", currentStats.income),
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        // Tips Card with Percentage
                        HStack(spacing: 16) {
                            StatCard(
                                title: tipsText,
                                value: String(format: "$%.2f", currentStats.tips),
                                icon: "banknote.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: tipPercentageText,
                                value: String(format: "%.1f%%", currentStats.tipPercentage),
                                icon: "percent",
                                color: .purple
                            )
                        }
                        
                        // Hours and Sales
                        HStack(spacing: 16) {
                            StatCard(
                                title: hoursText,
                                value: String(format: "%.1f", currentStats.hours),
                                icon: "clock.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: salesText,
                                value: String(format: "$%.0f", currentStats.sales),
                                icon: "cart.fill",
                                color: .indigo
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(dashboardTitle)
            .background(Color(.systemGroupedBackground))
        }
        .task {
            await loadStats()
        }
        .onChange(of: selectedPeriod) {
            Task {
                await loadStats()
            }
        }
    }
    
    var currentStats: Stats {
        switch selectedPeriod {
        case 1: return weekStats
        case 2: return monthStats
        default: return todayStats
        }
    }
    
    func loadStats() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let today = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var query = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId)
            
            // Filter based on period
            switch selectedPeriod {
            case 0: // Today
                query = query.eq("shift_date", value: dateFormatter.string(from: today))
            case 1: // This Week
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
                query = query.gte("shift_date", value: dateFormatter.string(from: weekAgo))
            case 2: // This Month
                let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: today)!
                query = query.gte("shift_date", value: dateFormatter.string(from: monthAgo))
            default:
                break
            }
            
            let shifts: [ShiftIncome] = try await query.execute().value
            
            // Calculate totals
            var stats = Stats()
            for shift in shifts {
                stats.hours += shift.hours
                stats.sales += shift.sales
                stats.tips += shift.tips
                stats.income += shift.total_income ?? 0
            }
            
            if stats.sales > 0 {
                stats.tipPercentage = (stats.tips / stats.sales) * 100
            }
            
            // Update appropriate stats
            switch selectedPeriod {
            case 1: weekStats = stats
            case 2: monthStats = stats
            default: todayStats = stats
            }
            
        } catch {
            print("Error loading stats: \(error)")
        }
    }
    
    // Localization
    var dashboardTitle: String {
        switch language {
        case "fr": return "Tableau de bord"
        case "es": return "Panel de control"
        default: return "Dashboard"
        }
    }
    
    var todayText: String {
        switch language {
        case "fr": return "Aujourd'hui"
        case "es": return "Hoy"
        default: return "Today"
        }
    }
    
    var weekText: String {
        switch language {
        case "fr": return "Semaine"
        case "es": return "Semana"
        default: return "Week"
        }
    }
    
    var monthText: String {
        switch language {
        case "fr": return "Mois"
        case "es": return "Mes"
        default: return "Month"
        }
    }
    
    var totalIncomeText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingreso total"
        default: return "Total Income"
        }
    }
    
    var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }
    
    var tipPercentageText: String {
        switch language {
        case "fr": return "% Pourboire"
        case "es": return "% Propina"
        default: return "Tip %"
        }
    }
    
    var hoursText: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }
    
    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
