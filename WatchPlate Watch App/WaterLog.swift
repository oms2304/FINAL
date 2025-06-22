import SwiftUI

struct WaterLog: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Define proportions
        let width = rect.width
        let height = rect.height
        let neckHeight = height * 0.1
        let neckWidth = width * 0.3
        let capHeight = neckHeight
        let bodyCornerRadius = width * 0.24
        let transitionRadius = width * 0.1
        
        // Start at bottom center
        path.move(to: CGPoint(x: width / 2, y: height))
        
        // Bottom right curve
        path.addArc(center: CGPoint(x: width * 0.75, y: height - bodyCornerRadius),
                    radius: bodyCornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(0),
                    clockwise: true)
        
        // Right body up
        path.addLine(to: CGPoint(x: width * 0.89 + transitionRadius, y: neckHeight + capHeight + transitionRadius))
        
        // Right body-to-neck curve
        path.addArc(center: CGPoint(x: width * 0.89, y: neckHeight + capHeight + transitionRadius),
                    radius: transitionRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(-50),
                    clockwise: true)
        
        // Right neck in
        path.addLine(to: CGPoint(x: width / 2 + neckWidth / 2, y: capHeight))
        
        // Cap right curve
        let capCornerRadius = neckWidth * 0.2
        path.addArc(center: CGPoint(x: width / 2 + neckWidth / 2 - capCornerRadius, y: capCornerRadius),
                    radius: capCornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(-90),
                    clockwise: true)
        
        // Top straight across
        path.addLine(to: CGPoint(x: width / 2 - neckWidth / 2 + capCornerRadius, y: 0))
        
        // Cap left curve
        path.addArc(center: CGPoint(x: width / 2 - neckWidth / 2 + capCornerRadius, y: capCornerRadius),
                    radius: capCornerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-180),
                    clockwise: true)
        
        // Left neck out
        path.addLine(to: CGPoint(x: width / 2 - neckWidth / 2, y: capHeight))
        
        // Left neck to body transition
        path.addLine(to: CGPoint(x: width * 0.08, y: neckHeight + capHeight))
        
        // Left body-to-neck curve (mirror of right)
        path.addArc(center: CGPoint(x: width * 0.12, y: neckHeight + capHeight + transitionRadius),
                    radius: transitionRadius,
                    startAngle: .degrees(-140),
                    endAngle: .degrees(-170),
                    clockwise: true)
        
        // Left body down
        path.addLine(to: CGPoint(x: width * 0.25 - bodyCornerRadius, y: height - bodyCornerRadius))
        
        // Bottom left curve
        path.addArc(center: CGPoint(x: width * 0.25, y: height - bodyCornerRadius),
                    radius: bodyCornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(90),
                    clockwise: true)
        
        // Close path
        path.closeSubpath()
        
        return path
    }
}

struct WaterBottleView: View {
    @State private var fillLevel: CGFloat = 0.3  // 0.0 to 1.0
    @State private var lastFillLevel: CGFloat = 0.3
    
    var body: some View {
        GeometryReader { geometry in
            let minSide = min(geometry.size.width, geometry.size.height)
            let bottleWidth = minSide * 0.5
            let bottleHeight = minSide * 1.0
            
            VStack(spacing: 10){
                ZStack {
                    // Bottle Outline
                    WaterLog()
                        .stroke(Color.white, lineWidth: minSide * 0.01)
                        .frame(width: bottleWidth, height: bottleHeight)
                    
                    // Fill shape masked by the bottle
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue.opacity(0.7)]),
                            startPoint: .bottom, endPoint: .top ))
                        .frame(width: bottleWidth, height: bottleHeight * fillLevel)
                        .offset(y: bottleHeight * (1 - fillLevel) / 2)  
                        .mask(
                            WaterLog()
                                .frame(width: bottleWidth, height: bottleHeight)
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .focusable(true)
                .digitalCrownRotation(
                    Binding(get: { fillLevel }, set: { newValue in
                        if newValue > lastFillLevel {
                            fillLevel = min(newValue, 1.0)
                            lastFillLevel = fillLevel
                        }
                    }
                           ),
                    from: 0.0,
                    through: 1.0,
                    by: 0.01,
                    sensitivity: .low,
                    isContinuous: true,
                    isHapticFeedbackEnabled: true
                )
                ZStack{
//                    Rectangle()
//                        .fill(Color.gray.opacity(0.6))
//                        .cornerRadius(20)
//                        .frame(width: 90)
                        
                    Text("\(Int(fillLevel * 64)) / 64 oz")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                }
                    
            }}
        .padding()
    }
}

#Preview {
    WaterBottleView()
}
