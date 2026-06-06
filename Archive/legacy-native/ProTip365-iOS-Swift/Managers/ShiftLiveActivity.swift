import ActivityKit
import WidgetKit
import SwiftUI

// 1. ATTRIBUTES: Data passed to start the activity
struct ShiftAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data
        var duration: Double
        var currentEarnings: Double
    }

    // Static data
    var shiftStartTime: Date
    var hourlyRate: Double
}

// 2. VIEW: The UI for the Lock Screen and Dynamic Island
// NOTE: This code strictly belongs in a Widget Extension target.
// Providing it here for reference/copy-paste into the extension.

struct ShiftLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShiftAttributes.self) { context in
            // MARK: - Lock Screen / Banner UI
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.badge.fill")
                        .foregroundStyle(.blue)
                    Text("Shift in Progress")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(timerInterval: context.attributes.shiftStartTime...Date.distantFuture, countsDown: false)
                        .monospacedDigit()
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Estimated")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(formatCurrency(context.state.currentEarnings))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Rate")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                         Text("$\(String(format: "%.0f", context.attributes.hourlyRate))/hr")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            // MARK: - Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        Text("Shift")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.shiftStartTime...Date.distantFuture, countsDown: false)
                        .monospacedDigit()
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(formatCurrency(context.state.currentEarnings))
                         .font(.title)
                         .fontWeight(.bold)
                         .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Optional: Action buttons could go here
                }
            } compactLeading: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text(timerInterval: context.attributes.shiftStartTime...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundStyle(.green)
            } minimal: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.green)
            }
            .keylineTint(Color.blue)
        }
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
