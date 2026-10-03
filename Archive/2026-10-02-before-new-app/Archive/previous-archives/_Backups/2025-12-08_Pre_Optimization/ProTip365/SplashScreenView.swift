import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var size = 0.8
    @State private var opacity = 0.5
    @AppStorage("language") private var language = "en"

    var body: some View {
        ZStack {
            // Background - solid color like system launch screen
            Color(.systemBackground)
                .ignoresSafeArea()

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.8, blue: 1.0),     // Light blue
                    Color(red: 1.0, green: 0.7, blue: 0.9),     // Light pink
                    Color(red: 0.8, green: 0.7, blue: 1.0)      // Light purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.2)
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // App Icon
                Image("Logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 10)

                // App Name
                HStack(spacing: 0) {
                    Text("ProTip")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("365")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }

                // Catchphrase
                Text(catchphrase)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }

                // Dismiss splash screen after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isActive = false
                    }
                }
            }
        }
    }

    private var catchphrase: String {
        switch language {
        case "fr":
            return "Maximisez vos revenus, un pourboire à la fois"
        case "es":
            return "Maximiza tus ingresos, una propina a la vez"
        default:
            return "Maximize Your Tips, One Shift at a Time"
        }
    }
}
