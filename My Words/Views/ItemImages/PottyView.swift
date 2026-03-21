import SwiftUI

/// White training potty illustration
struct PottyView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Floor / bathroom tile hint
                Rectangle()
                    .fill(Color(red: 0.92, green: 0.91, blue: 0.88))
                    .frame(width: w, height: h * 0.15)
                    .position(x: w * 0.5, y: h * 0.92)

                // Tile line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.85))
                    path.addLine(to: CGPoint(x: w, y: h * 0.85))
                }
                .stroke(Color(red: 0.82, green: 0.8, blue: 0.77), lineWidth: 1)

                // Potty base - wider bottom
                Path { path in
                    path.move(to: CGPoint(x: w * 0.15, y: h * 0.85))
                    path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.85))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.8, y: h * 0.7),
                        control: CGPoint(x: w * 0.87, y: h * 0.78)
                    )
                    path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.7))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.15, y: h * 0.85),
                        control: CGPoint(x: w * 0.13, y: h * 0.78)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.95), Color(white: 0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Potty bowl
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.45))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.8, y: h * 0.45),
                        control: CGPoint(x: w * 0.5, y: h * 0.78)
                    )
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.42))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.2, y: h * 0.42),
                        control: CGPoint(x: w * 0.5, y: h * 0.72)
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.97), Color(white: 0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Bowl inner shadow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.85), Color(white: 0.93)],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.2
                        )
                    )
                    .frame(width: w * 0.45, height: h * 0.15)
                    .position(x: w * 0.5, y: h * 0.52)

                // Seat rim - top oval
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [Color(white: 0.85), Color(white: 0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: w * 0.06
                    )
                    .frame(width: w * 0.55, height: h * 0.12)
                    .position(x: w * 0.5, y: h * 0.42)

                // Seat rim fill
                Ellipse()
                    .fill(Color(white: 0.96))
                    .frame(width: w * 0.55, height: h * 0.12)
                    .position(x: w * 0.5, y: h * 0.42)

                // Seat opening
                Ellipse()
                    .fill(Color(white: 0.82))
                    .frame(width: w * 0.38, height: h * 0.07)
                    .position(x: w * 0.5, y: h * 0.42)

                // Back rest / splash guard
                Path { path in
                    path.move(to: CGPoint(x: w * 0.25, y: h * 0.42))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.75, y: h * 0.42),
                        control: CGPoint(x: w * 0.5, y: h * 0.2)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.25, y: h * 0.42),
                        control: CGPoint(x: w * 0.5, y: h * 0.28)
                    )
                }
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.98), Color(white: 0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Back rest outline
                Path { path in
                    path.move(to: CGPoint(x: w * 0.25, y: h * 0.42))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.75, y: h * 0.42),
                        control: CGPoint(x: w * 0.5, y: h * 0.2)
                    )
                }
                .stroke(Color(white: 0.8), lineWidth: 1.5)

                // Outline of whole potty
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.45))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.8, y: h * 0.45),
                        control: CGPoint(x: w * 0.5, y: h * 0.78)
                    )
                }
                .stroke(Color(white: 0.78), lineWidth: 1.5)

                // Potty base outline
                Path { path in
                    path.move(to: CGPoint(x: w * 0.15, y: h * 0.85))
                    path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.85))
                }
                .stroke(Color(white: 0.78), lineWidth: 1)

                // Small smiley face on the back rest
                Circle()
                    .fill(Color(red: 0.4, green: 0.75, blue: 0.95))
                    .frame(width: w * 0.08, height: w * 0.08)
                    .position(x: w * 0.5, y: h * 0.3)

                // Smiley eyes
                Circle()
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .frame(width: w * 0.015, height: w * 0.015)
                    .position(x: w * 0.475, y: h * 0.29)

                Circle()
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .frame(width: w * 0.015, height: w * 0.015)
                    .position(x: w * 0.525, y: h * 0.29)

                // Smiley mouth
                Path { path in
                    path.move(to: CGPoint(x: w * 0.48, y: h * 0.31))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.52, y: h * 0.31),
                        control: CGPoint(x: w * 0.5, y: h * 0.325)
                    )
                }
                .stroke(Color(red: 0.2, green: 0.2, blue: 0.3), lineWidth: 1)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview {
    PottyView()
        .frame(width: 250, height: 250)
        .padding()
}
