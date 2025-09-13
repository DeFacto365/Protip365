import SwiftUI

struct AchievementView: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background with glass effect
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .modifier(GlassEffectRoundedModifier(cornerRadius: 0))
            
            VStack(spacing: 30) {
                // Achievement Icon with enhanced glass effects
                ZStack {
                    Circle()
                        .fill(achievement.type.color)
                        .frame(width: 120, height: 120)
                        .modifier(GlassEffectModifier())
                        .shadow(color: achievement.type.color.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: achievement.type.icon)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .modifier(GlassEffectModifier())
                        .frame(width: 60, height: 60)
                }
                .scaleEffect(showConfetti ? 1.1 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                
                // Achievement Text with glass effects
                VStack(spacing: 12) {
                    Text("🎉 Achievement Unlocked! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .modifier(GlassEffectRoundedModifier(cornerRadius: 8))
                        .padding(.horizontal, 8)
                    
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(achievement.type.color)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(achievement.message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Continue Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(achievement.type.color)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .padding()
            
            // Confetti effect
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showConfetti = true
            }
        }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.5...1.0)
            )
            particles.append(particle)
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let opacity: Double
}
