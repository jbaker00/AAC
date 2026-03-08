import SwiftUI

/// Baby stroller illustration
struct StrollerView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Stroller canopy
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.45))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.65, y: h * 0.15),
                        control: CGPoint(x: w * 0.15, y: h * 0.1)
                    )
                    path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.15))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.3, y: h * 0.45),
                        control: CGPoint(x: w * 0.25, y: h * 0.15)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.35, blue: 0.2), Color(red: 0.85, green: 0.25, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Stroller seat/basket
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.45))
                    path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.45))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.8, green: 0.3, blue: 0.15))

                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.45))
                    path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.45))
                    path.closeSubpath()
                }
                .stroke(Color(red: 0.5, green: 0.15, blue: 0.05), lineWidth: 2)

                // Handle bar
                Path { path in
                    path.move(to: CGPoint(x: w * 0.55, y: h * 0.45))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.8, y: h * 0.2),
                        control: CGPoint(x: w * 0.75, y: h * 0.35)
                    )
                }
                .stroke(Color(red: 0.3, green: 0.3, blue: 0.3), style: StrokeStyle(lineWidth: w * 0.04, lineCap: .round))

                // Handle grip
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .frame(width: w * 0.08, height: h * 0.06)
                    .position(x: w * 0.81, y: h * 0.18)

                // Front axle
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.78))
                }
                .stroke(Color(red: 0.3, green: 0.3, blue: 0.3), lineWidth: w * 0.025)

                // Rear axle
                Path { path in
                    path.move(to: CGPoint(x: w * 0.55, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.78))
                }
                .stroke(Color(red: 0.3, green: 0.3, blue: 0.3), lineWidth: w * 0.025)

                // Front wheel
                ZStack {
                    Circle()
                        .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                    Circle()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .padding(w * 0.02)
                }
                .frame(width: w * 0.15, height: w * 0.15)
                .position(x: w * 0.2, y: h * 0.84)

                // Rear wheel
                ZStack {
                    Circle()
                        .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                    Circle()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .padding(w * 0.02)
                }
                .frame(width: w * 0.18, height: w * 0.18)
                .position(x: w * 0.62, y: h * 0.84)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview {
    StrollerView()
        .frame(width: 250, height: 250)
        .padding()
}
