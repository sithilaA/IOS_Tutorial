import SwiftUI

// MARK: - Shared Neon Color Palette
extension Color {
    static let neonPurple  = Color(red: 0.58, green: 0.27, blue: 1.00)
    static let neonCyan    = Color(red: 0.00, green: 0.90, blue: 1.00)
    static let neonGreen   = Color(red: 0.18, green: 1.00, blue: 0.45)
    static let neonOrange  = Color(red: 1.00, green: 0.55, blue: 0.00)
    static let neonRed     = Color(red: 1.00, green: 0.18, blue: 0.33)
    static let neonYellow  = Color(red: 1.00, green: 0.90, blue: 0.00)
    static let neonPink    = Color(red: 1.00, green: 0.20, blue: 0.80)
    static let darkBG      = Color(red: 0.05, green: 0.04, blue: 0.10)
    static let cardBG      = Color(red: 0.10, green: 0.09, blue: 0.18)
    static let cardStroke  = Color(red: 0.30, green: 0.20, blue: 0.55)
}

// MARK: - Neon Glow Modifier
struct NeonGlow: ViewModifier {
    var color: Color
    var radius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.85), radius: radius / 2)
            .shadow(color: color.opacity(0.55), radius: radius)
            .shadow(color: color.opacity(0.25), radius: radius * 2)
    }
}

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 14) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}

// MARK: - Glass Card Container
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    let content: Content
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardBG.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.cardStroke.opacity(0.6), lineWidth: 1.2)
                    )
            )
            .shadow(color: Color.neonPurple.opacity(0.15), radius: 16)
    }
}

// MARK: - Countdown Progress Bar
struct CountdownBar: View {
    var timeRemaining: Int
    var total: Int
    var barColor: Color

    private var progress: Double { Double(timeRemaining) / Double(total) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [barColor.opacity(0.6), barColor]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(progress), height: 6)
                    .neonGlow(barColor, radius: 6)
                    .animation(.easeInOut(duration: 0.8), value: timeRemaining)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - App Dark Background
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.darkBG,
                    Color(red: 0.07, green: 0.04, blue: 0.15),
                    Color.darkBG
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Path { path in
                    let cols = 8
                    let spacing = geo.size.width / CGFloat(cols)
                    for i in 0...cols {
                        let x = CGFloat(i) * spacing
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    let rows = 16
                    let rowSpacing = geo.size.height / CGFloat(rows)
                    for j in 0...rows {
                        let y = CGFloat(j) * rowSpacing
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.neonPurple.opacity(0.06), lineWidth: 0.5)
            }
            .ignoresSafeArea()
        }
    }
}
