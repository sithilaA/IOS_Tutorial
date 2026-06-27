import SwiftUI

// MARK: - Home Screen
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // ── Logo / Title ──
                    VStack(spacing: 8) {
                        Text("ARCADE")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(6)
                            .foregroundColor(Color.neonPurple.opacity(0.7))

                        Text("ZONE")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .tracking(8)
                            .foregroundColor(.white)
                            .neonGlow(.neonPurple, radius: 14)

                        Text("SELECT YOUR GAME")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundColor(Color.white.opacity(0.30))
                    }
                    .padding(.top, 70)
                    .padding(.bottom, 52)

                    // ── Game Mode Cards ──
                    VStack(spacing: 20) {
                        // Tap Frenzy Card
                        NavigationLink(destination: TapFrenzyView()) {
                            GameModeCard(
                                icon: "hand.tap.fill",
                                title: "TAP FRENZY",
                                subtitle: "Combo · Traps · Moving Target · Burst",
                                accentColor: .neonCyan,
                                badgeText: "WEEK 1",
                                badgeColor: .neonCyan
                            )
                        }
                        .buttonStyle(.plain)

                        // Light It Up Card
                        NavigationLink(destination: LightItUpView()) {
                            GameModeCard(
                                icon: "lightbulb.max.fill",
                                title: "LIGHT IT UP",
                                subtitle: "Grid grows · Window shrinks · 4 Levels",
                                accentColor: .neonYellow,
                                badgeText: "WEEK 2",
                                badgeColor: .neonYellow
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // ── Footer ──
                    Text("BSC(HONS) COMPUTING · iOS APP DEVELOPMENT")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(Color.white.opacity(0.15))
                        .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Game Mode Card Component
struct GameModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let badgeText: String
    let badgeColor: Color

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 20) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 62, height: 62)
                Circle()
                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 62, height: 62)
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(accentColor)
                    .neonGlow(accentColor, radius: 8)
            }

            // Text Info
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    // Badge
                    Text(badgeText)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(badgeColor.opacity(0.15))
                                .overlay(Capsule().stroke(badgeColor.opacity(0.5), lineWidth: 1))
                        )
                }
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor.opacity(0.6))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.cardBG.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(accentColor.opacity(isPressed ? 0.7 : 0.3), lineWidth: 1.5)
                )
        )
        .neonGlow(accentColor, radius: isPressed ? 12 : 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded   { _ in isPressed = false }
        )
    }
}

#Preview {
    ContentView()
}
