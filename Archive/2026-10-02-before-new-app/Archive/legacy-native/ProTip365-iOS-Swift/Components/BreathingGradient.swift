import SwiftUI

struct BreathingGradient: View {
    var colors: [Color]
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
            .animation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true).speed(1), value: start)
            .onAppear {
                withAnimation {
                    start = UnitPoint(x: 4, y: 0)
                    end = UnitPoint(x: 0, y: 2)
                }
            }
    }
}
