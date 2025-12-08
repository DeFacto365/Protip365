import SwiftUI

struct RollingNumberText: View {
    var value: Double
    var font: Font = .largeTitle
    var weight: Font.Weight = .bold
    var color: Color = .primary
    
    @State private var animationRange: [Int] = []
    
    var body: some View {
        HStack(spacing: 0) {
            Text("$")
                .font(font)
                .fontWeight(weight)
                .foregroundColor(color)
            
            ForEach(0..<animationRange.count, id: \.self) { index in
                Text("8") // Placeholder for size
                    .font(font)
                    .fontWeight(weight)
                    .opacity(0)
                    .overlay(
                        GeometryReader { proxy in
                            let size = proxy.size
                            
                            VStack(spacing: 0) {
                                ForEach(0...9, id: \.self) { number in
                                    Text("\(number)")
                                        .font(font)
                                        .fontWeight(weight)
                                        .foregroundColor(color)
                                        .frame(width: size.width, height: size.height, alignment: .center)
                                }
                            }
                            .offset(y: -CGFloat(animationRange[index]) * size.height)
                        }
                        .clipped()
                    )
            }
        }
        .onAppear {
            updateAnimation()
        }
        .onChange(of: value) { _, _ in
            updateAnimation()
        }
    }
    
    func updateAnimation() {
        let stringValue = String(format: "%.0f", value)
        animationRange = stringValue.compactMap { Int(String($0)) }
    }
}
