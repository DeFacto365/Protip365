import ActivityKit
import Foundation

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<ShiftAttributes>?
    
    private init() {}
    
    // Start a new Live Activity
    func startShift(startTime: Date, hourlyRate: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = ShiftAttributes(shiftStartTime: startTime, hourlyRate: hourlyRate)
        let contentState = ShiftAttributes.ContentState(duration: 0, currentEarnings: 0)
        
        do {
            let activity = try Activity<ShiftAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("🚀 Live Activity Started: \(activity.id)")
        } catch {
            print("❌ Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Update existing activity
    func updateShift(earnings: Double, duration: Double) {
        guard let activity = currentActivity else { return }
        
        let contentState = ShiftAttributes.ContentState(duration: duration, currentEarnings: earnings)
        
        Task {
            await activity.update(
                ActivityContent<ShiftAttributes.ContentState>(
                    state: contentState,
                    staleDate: nil
                )
            )
        }
    }
    
    // End the activity
    func stopShift() {
        guard let activity = currentActivity else { return }
        
        let finalContentState = activity.content.state
        
        Task {
            await activity.end(
                ActivityContent<ShiftAttributes.ContentState>(
                    state: finalContentState,
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            currentActivity = nil
            print("🏁 Live Activity Ended")
        }
    }
}
