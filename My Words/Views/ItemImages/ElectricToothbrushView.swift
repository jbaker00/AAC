import SwiftUI

/// Electric toothbrush illustration
struct ElectricToothbrushView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Brush head bristles
                ForEach(0..<5, id: \.self) { row in
                    ForEach(0..<3, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white)
                            .frame(width: w * 0.04, height: h * 0.04)
                            .position(
                                x: w * 0.42 + CGFloat(col) * w * 0.06,
                                y: h * 0.08 + CGFloat(row) * h * 0.03
                            )
                    }
                }

                // Brush head backing
                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.7, blue: 0.9), Color(red: 0.15, green: 0.55, blue: 0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: w * 0.22, height: h * 0.2)
                    .position(x: w * 0.5, y: h * 0.12)

                // Bristle tips on top of head
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: w * 0.02, height: h * 0.06)
                        .position(
                            x: w * 0.39 + CGFloat(i) * w * 0.035,
                            y: h * 0.04
                        )
                }

                // Neck connector
                RoundedRectangle(cornerRadius: w * 0.02)
                    .fill(Color(red: 0.75, green: 0.75, blue: 0.8))
                    .frame(width: w * 0.1, height: h * 0.06)
                    .position(x: w * 0.5, y: h * 0.24)

                // Main body
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.5, blue: 0.75),
                                Color(red: 0.1, green: 0.4, blue: 0.65),
                                Color(red: 0.15, green: 0.5, blue: 0.75)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: w * 0.25, height: h * 0.5)
                    .position(x: w * 0.5, y: h * 0.52)

                // Body stripe accent
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.2, green: 0.7, blue: 0.9))
                    .frame(width: w * 0.04, height: h * 0.35)
                    .position(x: w * 0.5, y: h * 0.52)

                // Power button
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.3, green: 0.85, blue: 0.5), Color(red: 0.2, green: 0.65, blue: 0.35)],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.05
                        )
                    )
                    .frame(width: w * 0.1, height: w * 0.1)
                    .position(x: w * 0.5, y: h * 0.38)

                // Power icon on button
                Image(systemName: "power")
                    .font(.system(size: w * 0.05, weight: .bold))
                    .foregroundColor(.white)
                    .position(x: w * 0.5, y: h * 0.38)

                // Bottom base
                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(Color(red: 0.1, green: 0.35, blue: 0.55))
                    .frame(width: w * 0.28, height: h * 0.08)
                    .position(x: w * 0.5, y: h * 0.8)

                // Charging indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .frame(width: w * 0.06, height: h * 0.015)
                    .position(x: w * 0.5, y: h * 0.85)

                // Motion lines (vibration effect)
                ForEach(0..<3, id: \.self) { i in
                    Path { path in
                        let startY = h * 0.06 + CGFloat(i) * h * 0.05
                        path.move(to: CGPoint(x: w * 0.68, y: startY))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.75, y: startY),
                            control: CGPoint(x: w * 0.715, y: startY - h * 0.015)
                        )
                    }
                    .stroke(Color(red: 0.5, green: 0.8, blue: 1.0), lineWidth: 1.5)
                }
            }
        }
        .aspectRatio(0.45, contentMode: .fit)
    }
}

#Preview {
    ElectricToothbrushView()
        .frame(width: 150, height: 300)
        .padding()
}
