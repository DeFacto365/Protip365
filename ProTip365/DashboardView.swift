import SwiftUI
import Supabase

struct DashboardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var todayStats = DashboardMetrics.Stats()
    @State private var weekStats = DashboardMetrics.Stats()
    @State private var monthStats = DashboardMetrics.Stats()
    @State private var yearStats = DashboardMetrics.Stats()
    @State private var fourWeeksStats = DashboardMetrics.Stats()
    @State private var statsPreloaded = false
    @State private var initialLoadStarted = false
    @State private var selectedPeriod = 0
    @State private var monthViewType = 0 // 0 = Calendar Month, 1 = 4 Weeks Pay
    @State private var isLoading = false
    @State private var showingDetail = false
    @State private var detailViewData: DashboardMetrics.DetailViewData? = nil
    @State private var editingShift: ShiftIncome? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var userTargets = DashboardMetrics.UserTargets()
    @AppStorage("averageDeductionPercentage") private var averageDeductionPercentage: Double = 30.0

    // New managers for Phase 1 & 2 features
    @StateObject private var exportManager = ExportManager()
    @StateObject private var achievementManager = AchievementManager()
    @EnvironmentObject var alertManager: AlertManager
    @Namespace private var namespace
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var shareText = ""


    @AppStorage("language") private var language = "en"
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false

    // Localization
    private var localization: DashboardLocalization {
        DashboardLocalization(language: language)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass Background with extension effect
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()

                ScrollView {
                    VStack(spacing: Constants.dashboardSectionSpacing) {
                        // Period Selector (Contextual Layer)
                        DashboardPeriodSelector(
                            selectedPeriod: $selectedPeriod,
                            monthViewType: $monthViewType,
                            localization: localization
                        )

                        // Stats Cards (Main Content Layer)
                        DashboardStatsCards(
                            currentStats: currentStats,
                            userTargets: userTargets,
                            selectedPeriod: selectedPeriod,
                            monthViewType: monthViewType,
                            averageDeductionPercentage: averageDeductionPercentage,
                            defaultHourlyRate: defaultHourlyRate,
                            localization: localization,
                            detailViewData: $detailViewData
                        )
                        .onAppear {
                            #if DEBUG
                            print("🎯 Stats Cards Section Appeared")
                            #endif
                        }
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? Spacing.xxxxl : Spacing.lg)  // Reduced from 26 to 12 for iPhone
                    .padding(.bottom, horizontalSizeClass == .regular ? Spacing.xxl : (Constants.tabBarHeight + Spacing.xl))  // Reduced bottom padding
                    .frame(maxWidth: .infinity)
                }
                .refreshable {
                    // Force fresh data load on pull-to-refresh
                    await MainActor.run {
                        // Reset preloaded flag to ensure fresh fetch
                        statsPreloaded = false
                    }

                    // Fetch fresh data from Supabase
                    await preloadAllStats(forceRefresh: true)
                    await loadTargets()

                    // Check for achievements after refresh
                    await MainActor.run {
                        achievementManager.checkForAchievements(shifts: currentStats.shifts, currentStats: currentStats, targets: userTargets)
                        alertManager.checkForMissingShifts(shifts: currentStats.shifts, targets: userTargets)
                        alertManager.checkForTargetAchievements(currentStats: currentStats, targets: userTargets, period: selectedPeriod)
                    }
                }
                
                // Loading indicator overlay (show during initial load)
                if (isLoading || !statsPreloaded) && initialLoadStarted {
                    ZStack {
                        Color.primary.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text(localization.loadingStatsText)
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(Spacing.xxxl)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .navigationTitle(localization.proTip365Text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NotificationBell(alertManager: alertManager)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    // App logo
                    Image("Logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .fullScreenCover(item: horizontalSizeClass == .regular ? $detailViewData : .constant(nil)) { data in
                DetailView(
                    shifts: data.shifts.sorted { $0.shift_date > $1.shift_date },
                    detailType: data.type,
                    periodText: data.period,
                    onEditShift: { shift in
                        editingShift = shift
                        detailViewData = nil
                    }
                )
            }
            .sheet(item: horizontalSizeClass != .regular ? $detailViewData : .constant(nil)) { data in
                DetailView(
                    shifts: data.shifts.sorted { $0.shift_date > $1.shift_date },
                    detailType: data.type,
                    periodText: data.period,
                    onEditShift: { shift in
                        editingShift = shift
                        detailViewData = nil
                    }
                )
            }
            .task {
                // Use task modifier for initial load - runs once when view appears
                if !initialLoadStarted {
                    initialLoadStarted = true
                    let startTime = Date()
                    print("📊 Dashboard - Initial load starting at \(startTime)")
                    await preloadAllStats()
                    await loadTargets()
                    let loadTime = Date().timeIntervalSince(startTime)
                    print("📊 Dashboard - Load completed in \(String(format: "%.2f", loadTime)) seconds")

                    // Check for achievements after initial load
                    achievementManager.checkForAchievements(shifts: currentStats.shifts, currentStats: currentStats, targets: userTargets)

                    // Check for alerts after initial load
                    alertManager.checkForMissingShifts(shifts: currentStats.shifts, targets: userTargets)
                    alertManager.checkForTargetAchievements(currentStats: currentStats, targets: userTargets, period: selectedPeriod)
                }
            }
            .onAppear {
                // Double-check on appear - only if task hasn't started
                if !initialLoadStarted && !statsPreloaded {
                    initialLoadStarted = true
                    Task {
                        await preloadAllStats()
                        await loadTargets()
                    }
                } else if statsPreloaded {
                    // If we already have data but view is appearing again,
                    // do a background refresh to catch any changes from other devices
                    Task {
                        await preloadAllStats(forceRefresh: true)
                    }
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                // Update view when period changes
                Task {
                    // Small delay to ensure UI updates
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            .onChange(of: monthViewType) { _, _ in
                // Update view when month view type changes
                Task {
                    // Small delay to ensure UI updates
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(exportManager: exportManager, shifts: currentStats.shifts, language: language)
            }
            .sheet(isPresented: $showingShareSheet) {
                TextShareSheet(text: shareText)
            }
            .sheet(isPresented: $achievementManager.showAchievement) {
                AchievementView(achievement: achievementManager.currentAchievement!)
            }
            .sheet(item: $editingShift, onDismiss: {
                // Reload data after editing
                Task {
                    await preloadAllStats()
                }
            }) { shift in
                AddEntryView(editingShift: shift)
                    .environmentObject(SupabaseManager.shared)
            }
        }
    }
    
    var currentStats: DashboardMetrics.Stats {
        switch selectedPeriod {
        case 1: return weekStats
        case 2:
            // Month tab - check if Calendar Month or 4 Weeks
            return monthViewType == 0 ? monthStats : fourWeeksStats
        case 3: return yearStats
        default: return todayStats
        }
    }

    var periodText: String {
        DashboardMetrics.getPeriodText(
            selectedPeriod: selectedPeriod,
            monthViewType: monthViewType,
            localization: localization
        )
    }
    
    func shareCurrentStats() {
        shareText = DashboardMetrics.generateShareText(
            currentStats: currentStats,
            selectedPeriod: selectedPeriod
        )
        showingShareSheet = true
    }
    
    func loadTargets() async {
        let result = await DashboardCharts.loadTargets()
        userTargets = result.targets
        defaultHourlyRate = result.hourlyRate
        averageDeductionPercentage = result.deductionPercentage
    }
    
    func preloadAllStats(forceRefresh: Bool = false) async {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
                statsPreloaded = true
                if forceRefresh {
                    HapticFeedback.success()
                }
            }
        }

        let result = await DashboardCharts.loadAllStats(
            forceRefresh: forceRefresh,
            defaultHourlyRate: defaultHourlyRate,
            averageDeductionPercentage: averageDeductionPercentage
        )

        await MainActor.run {
            // Clear existing data if force refresh
            if forceRefresh {
                todayStats = DashboardMetrics.Stats()
                weekStats = DashboardMetrics.Stats()
                monthStats = DashboardMetrics.Stats()
                yearStats = DashboardMetrics.Stats()
                fourWeeksStats = DashboardMetrics.Stats()
            }

            // Update with fresh data
            todayStats = result.todayStats
            weekStats = result.weekStats
            monthStats = result.monthStats
            yearStats = result.yearStats
            fourWeeksStats = result.fourWeeksStats
        }
    }
    





}

struct TextShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
