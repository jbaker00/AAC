import SwiftUI

/// Lactaid 2% Lactose-Free Milk carton illustration
struct MilkCartonView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Carton body - white base
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(Color.white)
                    .frame(width: w * 0.6, height: h * 0.75)
                    .position(x: w * 0.5, y: h * 0.55)

                // Carton body - blue accent band
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.3, blue: 0.65),
                                Color(red: 0.0, green: 0.4, blue: 0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.6, height: h * 0.35)
                    .position(x: w * 0.5, y: h * 0.72)

                // Carton outline
                RoundedRectangle(cornerRadius: w * 0.06)
                    .stroke(Color(red: 0.0, green: 0.25, blue: 0.55), lineWidth: 2)
                    .frame(width: w * 0.6, height: h * 0.75)
                    .position(x: w * 0.5, y: h * 0.55)

                // Gable top (roof of carton)
                Path { path in
                    let cx = w * 0.5
                    let leftX = w * 0.2
                    let rightX = w * 0.8
                    let topY = h * 0.1
                    let baseY = h * 0.22

                    path.move(to: CGPoint(x: leftX, y: baseY))
                    path.addLine(to: CGPoint(x: cx, y: topY))
                    path.addLine(to: CGPoint(x: rightX, y: baseY))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.0, green: 0.35, blue: 0.7))

                Path { path in
                    let cx = w * 0.5
                    let leftX = w * 0.2
                    let rightX = w * 0.8
                    let topY = h * 0.1
                    let baseY = h * 0.22

                    path.move(to: CGPoint(x: leftX, y: baseY))
                    path.addLine(to: CGPoint(x: cx, y: topY))
                    path.addLine(to: CGPoint(x: rightX, y: baseY))
                    path.closeSubpath()
                }
                .stroke(Color(red: 0.0, green: 0.25, blue: 0.55), lineWidth: 2)

                // Cap on top
                Circle()
                    .fill(Color(red: 0.0, green: 0.45, blue: 0.85))
                    .frame(width: w * 0.12, height: w * 0.12)
                    .position(x: w * 0.5, y: h * 0.12)

                // "LACTAID" text
                Text("LACTAID")
                    .font(.system(size: w * 0.09, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.3, blue: 0.65))
                    .position(x: w * 0.5, y: h * 0.35)

                // "2%" text
                Text("2%")
                    .font(.system(size: w * 0.16, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))
                    .position(x: w * 0.5, y: h * 0.48)

                // "Lactose Free" subtitle
                Text("Lactose Free")
                    .font(.system(size: w * 0.065, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .position(x: w * 0.5, y: h * 0.62)

                // Milk splash decoration
                Ellipse()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: w * 0.25, height: h * 0.08)
                    .position(x: w * 0.5, y: h * 0.76)
            }
        }
        .aspectRatio(0.65, contentMode: .fit)
    }
}

#Preview {
    MilkCartonView()
        .frame(width: 200, height: 300)
        .padding()
}
