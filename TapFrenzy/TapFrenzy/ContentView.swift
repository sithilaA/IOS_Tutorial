import SwiftUI
internal import Combine

// MARK: - Color Palette
extension Color {
    static let neonPurple   = Color(red: 0.58, green: 0.27, blue: 1.0)
    static let neonCyan     = Color(red: 0.0,  green: 0.90, blue: 1.0)
    static let neonGreen    = Color(red: 0.18, green: 1.0,  blue: 0.45)
    static let neonOrange   = Color(red: 1.0,  green: 0.55, blue: 0.0)
    static let neonRed      = Color(red: 1.0,  green: 0.18, blue: 0.33)
    static let darkBG       = Color(red: 0.05, green: 0.04, blue: 0.10)
    static let cardBG       = Color(red: 0.10, green: 0.09, blue: 0.18)
    static let cardStroke   = Color(red: 0.30, green: 0.20, blue: 0.55)
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

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardBG.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.cardStroke.opacity(0.6), lineWidth: 1.2)
                    )
            )
            .shadow(color: Color.neonPurple.opacity(0.15), radius: 16)
    }
}

// MARK: - Animated Countdown Ring
struct CountdownRing: View {
    var timeRemaining: Int
    var total: Int = 10
    var ringColor: Color

    private var progress: Double { Double(timeRemaining) / Double(total) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ringColor.opacity(0.4), ringColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: timeRemaining)
                .neonGlow(ringColor, radius: 10)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    // Base State Architecture
    @State var score = 0
    @State var timeRemaining = 10
    @State var highScore = 0

    // Challenge 1: Combo Tracking
    @State var comboMultiplier = 1
    @State var lastTapTime = Date()

    // Challenge 2: Dynamic Colors
    @State var buttonColor: Color = .blue

    // Challenge 3: Spatial Offsets (Movement Container Boundings)
    @State var buttonOffset = CGSize.zero

    // Challenge 5: Flash Burst Mode Flag
    @State var isBurstActive = false

    // UI Feedback State
    @State private var tapFeedbackScale: CGFloat = 1.0
    @State private var scorePopOffset: CGFloat = 0
    @State private var scorePopOpacity: Double = 0
    @State private var lastScoreDelta: Int = 0
    @State private var pulseRing: Bool = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Map logical button color to neon palette
    private var neonButtonColor: Color {
        if isBurstActive { return .neonOrange }
        switch buttonColor {
        case .green: return .neonGreen
        case .gray:  return .neonRed
        default:     return .neonCyan
        }
    }

    private var timerRingColor: Color {
        timeRemaining > 5 ? .neonCyan : .neonRed
    }

    var body: some View {
        ZStack {
            // ── Background Gradient ──
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

            // Ambient grid lines for depth
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
                .stroke(Color.neonPurple.opacity(0.07), lineWidth: 0.5)
            }
            .ignoresSafeArea()

            if timeRemaining > 0 {
                gameView
            } else {
                gameOverView
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Game View
    private var gameView: some View {
        VStack(spacing: 0) {
            // ── Header Bar ──
            headerBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // ── Burst Banner ──
            burstBanner
                .padding(.top, 8)

            Spacer()

            // ── Arena ──
            arenaView
                .padding(.horizontal, 20)

            Spacer()

            // ── Combo Indicator ──
            comboIndicator
                .padding(.bottom, 24)
        }
        .onReceive(timer) { _ in
            processGameTick()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // Timer Card
            GlassCard {
                VStack(spacing: 4) {
                    Text("TIME")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.neonCyan.opacity(0.7))
                        .tracking(2)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(timerRingColor)
                            .neonGlow(timerRingColor, radius: 8)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: timeRemaining)
                        Text("s")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(timerRingColor.opacity(0.7))
                    }
                }
            }

            Spacer()

            // App Title
            VStack(spacing: 2) {
                Text("TAP")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(Color.neonPurple.opacity(0.6))
                Text("FRENZY")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white)
                    .neonGlow(.neonPurple, radius: 6)
            }

            Spacer()

            // Score Card
            GlassCard {
                VStack(spacing: 4) {
                    Text("SCORE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.neonCyan.opacity(0.7))
                        .tracking(2)
                    Text("\(score)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.neonCyan)
                        .neonGlow(.neonCyan, radius: 8)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: score)
                }
            }
        }
    }

    // MARK: - Burst Banner
    @ViewBuilder
    private var burstBanner: some View {
        if isBurstActive {
            HStack(spacing: 8) {
                Text("⚡")
                Text("BURST MODE  ·  DOUBLE POINTS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                Text("⚡")
            }
            .foregroundColor(Color.neonOrange)
            .padding(.vertical, 7)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(Color.neonOrange.opacity(0.15))
                    .overlay(Capsule().stroke(Color.neonOrange.opacity(0.5), lineWidth: 1))
            )
            .neonGlow(.neonOrange, radius: 10)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        } else {
            Color.clear.frame(height: 34)
        }
    }

    // MARK: - Arena View
    private var arenaView: some View {
        ZStack {
            // Arena background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.cardBG.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.cardStroke.opacity(0.4), lineWidth: 1)
                )

            // Corner decorations
            VStack {
                HStack {
                    cornerDot
                    Spacer()
                    cornerDot
                }
                Spacer()
                HStack {
                    cornerDot
                    Spacer()
                    cornerDot
                }
            }
            .padding(16)

            // Label
            VStack {
                Text("ARENA")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(Color.white.opacity(0.10))
                Spacer()
            }
            .padding(.top, 12)

            // Score delta pop
            if scorePopOpacity > 0 {
                Text(lastScoreDelta >= 0 ? "+\(lastScoreDelta)" : "\(lastScoreDelta)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(lastScoreDelta >= 0 ? .neonGreen : .neonRed)
                    .neonGlow(lastScoreDelta >= 0 ? .neonGreen : .neonRed, radius: 8)
                    .offset(y: scorePopOffset)
                    .opacity(scorePopOpacity)
            }

            // TAP Button in GeometryReader for bounded movement
            GeometryReader { geometry in
                ZStack {
                    Button(action: { handleTap() }) {
                        ZStack {
                            // Outer ring
                            CountdownRing(
                                timeRemaining: timeRemaining,
                                ringColor: neonButtonColor
                            )
                            .frame(width: 140, height: 140)

                            // Button body
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            neonButtonColor.opacity(0.55),
                                            neonButtonColor.opacity(0.20)
                                        ]),
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 55
                                    )
                                )
                                .frame(width: 108, height: 108)
                                .overlay(
                                    Circle()
                                        .stroke(neonButtonColor, lineWidth: 2)
                                )
                                .neonGlow(neonButtonColor, radius: 18)

                            // Label
                            VStack(spacing: 2) {
                                Text("TAP!")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .neonGlow(.white, radius: 4)
                                if comboMultiplier > 1 {
                                    Text("×\(comboMultiplier)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(neonButtonColor)
                                }
                            }
                        }
                    }
                    .scaleEffect(tapFeedbackScale)
                    .scaleEffect(CGFloat(timeRemaining) / 10.0 * 0.65 + 0.35)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(buttonOffset)
                .onAppear { buttonOffset = CGSize.zero }
            }
            .frame(height: 310)
        }
        .frame(height: 340)
        .clipped()
    }

    private var cornerDot: some View {
        Circle()
            .fill(Color.neonPurple.opacity(0.35))
            .frame(width: 5, height: 5)
    }

    // MARK: - Combo Indicator
    private var comboIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < comboMultiplier
                          ? Color.neonOrange
                          : Color.white.opacity(0.10))
                    .frame(width: 28, height: 6)
                    .neonGlow(i < comboMultiplier ? .neonOrange : .clear, radius: 4)
                    .animation(.spring(response: 0.25), value: comboMultiplier)
            }
            if comboMultiplier > 5 {
                Text("×\(comboMultiplier)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.neonOrange)
                    .neonGlow(.neonOrange, radius: 6)
            }
        }
    }

    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: 6) {
                Text("GAME")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.white)
                Text("OVER")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.neonRed)
                    .neonGlow(.neonRed, radius: 16)
            }
            .padding(.bottom, 36)

            // Score Cards
            VStack(spacing: 16) {
                // Final Score
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FINAL SCORE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(Color.neonCyan.opacity(0.7))
                            Text("\(score)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(.neonCyan)
                                .neonGlow(.neonCyan, radius: 12)
                        }
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.neonCyan)
                            .neonGlow(.neonCyan, radius: 10)
                    }
                }
                .padding(.horizontal, 24)

                // High Score
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HIGH SCORE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(Color.neonOrange.opacity(0.7))
                            Text("\(highScore)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.neonOrange)
                                .neonGlow(.neonOrange, radius: 10)
                        }
                        Spacer()
                        Image(systemName: score >= highScore ? "crown.fill" : "trophy.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.neonOrange)
                            .neonGlow(.neonOrange, radius: 8)
                    }
                }
                .padding(.horizontal, 24)

                // New high score badge
                if score >= highScore && highScore > 0 {
                    Text("🏆  NEW HIGH SCORE!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.neonOrange)
                        .neonGlow(.neonOrange, radius: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer()

            // Play Again Button
            Button(action: { resetGame() }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                    Text("PLAY AGAIN")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundColor(.darkBG)
                .padding(.vertical, 18)
                .padding(.horizontal, 48)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.neonCyan, .neonPurple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .neonGlow(.neonCyan, radius: 14)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 52)
        }
    }

    // MARK: - APP REFACTOR MECHANICS ENGINE (Logic Unchanged)

    // Master Input Action Evaluator
    func handleTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) <= 0.5 {
            comboMultiplier += 1
        } else {
            comboMultiplier = 1
        }
        lastTapTime = now

        // Value computation bases
        var basePoint = 1
        if buttonColor == .gray {
            basePoint = -2  // Penalty state rule
        } else if buttonColor == .green {
            basePoint = 2   // Bonus state rule
        }

        if isBurstActive {
            basePoint *= 2  // Multiplier compounding for bursts
        }

        let delta = basePoint * comboMultiplier
        score += delta

        // UI Feedback
        showScorePop(delta: delta)
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 12)) {
            tapFeedbackScale = 0.88
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                tapFeedbackScale = 1.0
            }
        }
    }

    private func showScorePop(delta: Int) {
        lastScoreDelta = delta
        scorePopOffset = 0
        scorePopOpacity = 1
        withAnimation(.easeOut(duration: 0.6)) {
            scorePopOffset = -60
            scorePopOpacity = 0
        }
    }

    // 1-Second Cycle Process Loop Evaluator
    func processGameTick() {
        if timeRemaining > 0 {
            timeRemaining -= 1

            // Challenge 2: Every single second, shuffle button modifier distributions
            let roller = Int.random(in: 1...3)
            if roller == 1 {
                buttonColor = .green
            } else if roller == 2 {
                buttonColor = .gray
            } else {
                buttonColor = .blue
            }

            // Challenge 3: Relocate position coordinates every alternate second block
            if timeRemaining % 2 == 0 {
                withAnimation(.easeInOut(duration: 0.4)) {
                    buttonOffset = CGSize(
                        width: CGFloat.random(in: -80...80),
                        height: CGFloat.random(in: -110...110)
                    )
                }
            }

            // Challenge 5: Enable burst window state when remaining time falls to exactly 5 seconds
            if timeRemaining == 5 {
                isBurstActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isBurstActive = false
                }
            }
        }

        // Wrap up execution logic
        if timeRemaining == 0 {
            comboMultiplier = 1
            buttonOffset = CGSize.zero
            if score > highScore { highScore = score }
        }
    }

    // Master Match Reset Execution
    func resetGame() {
        score = 0
        timeRemaining = 10
        comboMultiplier = 1
        buttonColor = .blue
        buttonOffset = CGSize.zero
        isBurstActive = false
    }
}
