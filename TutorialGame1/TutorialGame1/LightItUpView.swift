import SwiftUI

// MARK: - Card Model
struct LightCard: Identifiable {
    let id: Int
    var isLit: Bool = false
}

// MARK: - Level Configuration
enum GameLevel: Int, CaseIterable {
    case l1 = 1, l2, l3, l4

    /// Elapsed seconds at which this level begins
    var startTime: Int { return (self.rawValue - 1) * 15 }

    /// Number of cards in the grid
    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }

    /// Grid columns
    var columns: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 3
        case .l4: return 3
        }
    }

    /// How long a card stays lit (seconds)
    var litWindow: Double {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    /// Cards lit simultaneously
    var litCount: Int { self == .l4 ? 2 : 1 }

    /// Neon glow colour per level (bonus challenge: distinct glow per level)
    var glowColor: Color {
        switch self {
        case .l1: return .neonCyan
        case .l2: return .neonGreen
        case .l3: return .neonYellow
        case .l4: return .neonPink
        }
    }

    var label: String { "LEVEL \(rawValue)" }
}

// MARK: - Light It Up Game View
struct LightItUpView: View {

    // ── Persistence ──
    @AppStorage("lightItUpHighScore") private var storedHighScore: Int = 0

    // ── Round Timer (60 seconds total) ──
    @State private var timeRemaining: Int = 60
    @State private var elapsedTime: Int = 0

    // ── Game State ──
    @State private var score: Int = 0
    @State private var lives: Int = 3              // Bonus: 3 lives system
    @State private var isGameOver: Bool = false
    @State private var isGameRunning: Bool = false

    // ── Card State ──
    @State private var cards: [LightCard] = []
    @State private var litCardTimer: Timer? = nil

    // ── Level Flash Overlay (Bonus: level-up flash) ──
    @State private var showLevelFlash: Bool = false
    @State private var flashLevel: GameLevel = .l1

    // ── Score Pop ──
    @State private var scorePopText: String = ""
    @State private var scorePopOffset: CGFloat = 0
    @State private var scorePopOpacity: Double = 0
    @State private var scorePopColor: Color = .neonGreen

    // ── Settings (Bonus: round length) ──
    @State private var showSettings: Bool = false
    @State private var roundLength: Int = 60

    // ── Combine timer ──
    let roundTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // ── Computed level from elapsed time ──
    private var currentLevel: GameLevel {
        switch elapsedTime {
        case 0..<15:  return .l1
        case 15..<30: return .l2
        case 30..<45: return .l3
        default:      return .l4
        }
    }

    private var previousLevel: GameLevel {
        switch elapsedTime - 1 {
        case 0..<15:  return .l1
        case 15..<30: return .l2
        case 30..<45: return .l3
        default:      return .l4
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: currentLevel.columns)
    }

    var body: some View {
        ZStack {
            AppBackground()

            if !isGameRunning && !isGameOver {
                startScreen
            } else if isGameOver {
                gameOverView
            } else {
                gameView
            }

            // ── Level-Up Flash Overlay ──
            if showLevelFlash {
                levelUpFlash
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.darkBG, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isGameRunning {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.neonYellow.opacity(0.8))
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .onReceive(roundTimer) { _ in
            guard isGameRunning && !isGameOver else { return }
            tickRound()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Start Screen
    private var startScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.neonYellow)
                    .neonGlow(.neonYellow, radius: 20)
                    .padding(.bottom, 12)

                Text("LIGHT IT UP")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(.white)
                    .neonGlow(.neonYellow, radius: 10)

                Text("Tap the lit card before it goes dark")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)

            // Level Preview Cards
            VStack(spacing: 12) {
                ForEach(GameLevel.allCases, id: \.rawValue) { level in
                    levelPreviewRow(level)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)

            // High Score
            if storedHighScore > 0 {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.neonOrange)
                            .neonGlow(.neonOrange, radius: 6)
                        Text("BEST")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundColor(Color.neonOrange.opacity(0.7))
                        Spacer()
                        Text("\(storedHighScore)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.neonOrange)
                            .neonGlow(.neonOrange, radius: 8)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }

            // Start Button
            Button(action: startGame) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("START  —  \(roundLength)s ROUND")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(1.5)
                }
                .foregroundColor(Color.darkBG)
                .padding(.vertical, 18)
                .padding(.horizontal, 40)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.neonYellow, .neonOrange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .neonGlow(.neonYellow, radius: 16)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func levelPreviewRow(_ level: GameLevel) -> some View {
        HStack(spacing: 14) {
            Text(level.label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(level.glowColor)
                .frame(width: 55, alignment: .leading)

            // Mini card grid preview
            HStack(spacing: 4) {
                ForEach(0..<min(level.cardCount, 9), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(i == 0 ? level.glowColor.opacity(0.8) : Color.white.opacity(0.10))
                        .frame(width: 16, height: 16)
                        .neonGlow(i == 0 ? level.glowColor : .clear, radius: 4)
                }
            }

            Spacer()

            Text("\(String(format: "%.1f", level.litWindow))s window")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.35))

            if level.litCount > 1 {
                Text("×\(level.litCount)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(level.glowColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(level.glowColor.opacity(0.15)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBG.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(level.glowColor.opacity(0.20), lineWidth: 1)
                )
        )
    }

    // MARK: - Main Game View
    private var gameView: some View {
        VStack(spacing: 0) {
            // ── HUD ──
            gameHUD
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)

            // ── Countdown Bar ──
            CountdownBar(
                timeRemaining: timeRemaining,
                total: roundLength,
                barColor: currentLevel.glowColor
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // ── Level Badge ──
            levelBadge
                .padding(.bottom, 16)

            Spacer()

            // ── Card Grid ──
            cardGrid
                .padding(.horizontal, 24)

            Spacer()

            // ── Lives Row ──
            livesRow
                .padding(.bottom, 28)
        }
    }

    // MARK: - HUD
    private var gameHUD: some View {
        HStack(spacing: 12) {
            GlassCard {
                VStack(spacing: 4) {
                    Text("TIME")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.neonYellow.opacity(0.7))
                        .tracking(2)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(timeRemaining > 15 ? .neonYellow : .neonRed)
                            .neonGlow(timeRemaining > 15 ? .neonYellow : .neonRed, radius: 8)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: timeRemaining)
                        Text("s")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color.neonYellow.opacity(0.7))
                    }
                }
            }

            Spacer()

            // Score pop overlay + SCORE card
            ZStack {
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

                if scorePopOpacity > 0 {
                    Text(scorePopText)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(scorePopColor)
                        .neonGlow(scorePopColor, radius: 8)
                        .offset(y: scorePopOffset)
                        .opacity(scorePopOpacity)
                }
            }
        }
    }

    // MARK: - Level Badge
    private var levelBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentLevel.glowColor)
                .frame(width: 8, height: 8)
                .neonGlow(currentLevel.glowColor, radius: 6)
            Text(currentLevel.label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(currentLevel.glowColor)
                .neonGlow(currentLevel.glowColor, radius: 6)
                .animation(.easeInOut, value: currentLevel.rawValue)
            Circle()
                .fill(currentLevel.glowColor)
                .frame(width: 8, height: 8)
                .neonGlow(currentLevel.glowColor, radius: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(currentLevel.glowColor.opacity(0.10))
                .overlay(Capsule().stroke(currentLevel.glowColor.opacity(0.4), lineWidth: 1))
        )
    }

    // MARK: - Card Grid
    private var cardGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(cards) { card in
                cardView(card)
                    .onTapGesture { handleCardTap(card) }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentLevel.rawValue)
    }

    private func cardView(_ card: LightCard) -> some View {
        let isLit = card.isLit
        let level = currentLevel

        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                isLit
                ? RadialGradient(
                    gradient: Gradient(colors: [level.glowColor.opacity(0.9), level.glowColor.opacity(0.4)]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 50
                  )
                : LinearGradient(
                    gradient: Gradient(colors: [Color.cardBG, Color.cardBG]),
                    startPoint: .top,
                    endPoint: .bottom
                  )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isLit ? level.glowColor : Color.cardStroke.opacity(0.4),
                        lineWidth: isLit ? 2 : 1
                    )
            )
            .overlay(
                // Bulb icon on lit cards
                Image(systemName: isLit ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isLit ? .white : Color.white.opacity(0.15))
            )
            .neonGlow(isLit ? level.glowColor : .clear, radius: isLit ? 14 : 0)
            .scaleEffect(isLit ? 1.06 : 1.0)
            .frame(height: cardHeight)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isLit)
    }

    private var cardHeight: CGFloat {
        switch currentLevel {
        case .l1: return 100
        case .l2: return 90
        case .l3: return 80
        case .l4: return 80
        }
    }

    // MARK: - Lives Row
    private var livesRow: some View {
        HStack(spacing: 10) {
            Text("LIVES")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundColor(Color.white.opacity(0.35))
            ForEach(0..<3) { i in
                Image(systemName: i < lives ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(i < lives ? .neonRed : Color.white.opacity(0.20))
                    .neonGlow(i < lives ? .neonRed : .clear, radius: 6)
                    .animation(.spring(response: 0.3), value: lives)
            }
        }
    }

    // MARK: - Level-Up Flash Overlay
    private var levelUpFlash: some View {
        ZStack {
            flashLevel.glowColor.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("LEVEL UP!")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(.white)
                    .neonGlow(flashLevel.glowColor, radius: 20)
                Text(flashLevel.label)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(flashLevel.glowColor)
                    .neonGlow(flashLevel.glowColor, radius: 10)
            }
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: - Settings Sheet (Bonus)
    private var settingsSheet: some View {
        ZStack {
            Color.darkBG.ignoresSafeArea()

            VStack(spacing: 32) {
                Text("SETTINGS")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(.white)
                    .padding(.top, 32)

                VStack(alignment: .leading, spacing: 14) {
                    Text("ROUND LENGTH")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(Color.white.opacity(0.4))

                    HStack(spacing: 12) {
                        ForEach([30, 60, 90], id: \.self) { secs in
                            Button {
                                roundLength = secs
                                timeRemaining = secs
                            } label: {
                                Text("\(secs)s")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(roundLength == secs ? Color.darkBG : .neonYellow)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(roundLength == secs ? Color.neonYellow : Color.neonYellow.opacity(0.10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.neonYellow.opacity(0.4), lineWidth: 1)
                                            )
                                    )
                                    .neonGlow(roundLength == secs ? .neonYellow : .clear, radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                Button("DONE") { showSettings = false }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundColor(Color.darkBG)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 48)
                    .background(Capsule().fill(Color.neonYellow))
                    .neonGlow(.neonYellow, radius: 10)
                    .buttonStyle(.plain)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: lives == 0 ? "heart.slash.fill" : "timer")
                    .font(.system(size: 42))
                    .foregroundColor(lives == 0 ? .neonRed : .neonYellow)
                    .neonGlow(lives == 0 ? .neonRed : .neonYellow, radius: 16)
                    .padding(.bottom, 12)

                Text(lives == 0 ? "OUT OF" : "TIME'S")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.white)
                Text(lives == 0 ? "LIVES" : "UP")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.neonRed)
                    .neonGlow(.neonRed, radius: 16)
            }
            .padding(.bottom, 36)

            VStack(spacing: 16) {
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

                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HIGH SCORE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(Color.neonOrange.opacity(0.7))
                            Text("\(storedHighScore)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.neonOrange)
                                .neonGlow(.neonOrange, radius: 10)
                        }
                        Spacer()
                        Image(systemName: score >= storedHighScore && score > 0 ? "crown.fill" : "trophy.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.neonOrange)
                            .neonGlow(.neonOrange, radius: 8)
                    }
                }
                .padding(.horizontal, 24)

                if score > 0 && score >= storedHighScore {
                    Text("🏆  NEW HIGH SCORE!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.neonOrange)
                        .neonGlow(.neonOrange, radius: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer()

            Button(action: resetGame) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                    Text("PLAY AGAIN")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundColor(Color.darkBG)
                .padding(.vertical, 18)
                .padding(.horizontal, 48)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.neonYellow, .neonOrange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .neonGlow(.neonYellow, radius: 14)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Game Logic

    func startGame() {
        score = 0
        lives = 3
        elapsedTime = 0
        timeRemaining = roundLength
        isGameOver = false
        isGameRunning = true
        rebuildGrid(for: .l1)
        scheduleLitCard(for: .l1)
    }

    func resetGame() {
        litCardTimer?.invalidate()
        litCardTimer = nil
        isGameRunning = false
        isGameOver = false
        cards = []
    }

    private func tickRound() {
        guard timeRemaining > 0 else {
            endGame()
            return
        }

        timeRemaining -= 1
        elapsedTime += 1

        let newLevel = currentLevel
        let oldLevel = previousLevel

        // Level transition
        if newLevel != oldLevel {
            litCardTimer?.invalidate()
            litCardTimer = nil
            rebuildGrid(for: newLevel)
            triggerLevelFlash(newLevel)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.scheduleLitCard(for: newLevel)
            }
        }
    }

    private func rebuildGrid(for level: GameLevel) {
        cards = (0..<level.cardCount).map { LightCard(id: $0) }
    }

    private func scheduleLitCard(for level: GameLevel) {
        litCardTimer?.invalidate()
        litCardTimer = nil

        guard isGameRunning && !isGameOver else { return }

        // Dim all first
        for i in cards.indices { cards[i].isLit = false }

        // Pick random lit cards
        let indices = Array(0..<cards.count).shuffled().prefix(level.litCount)
        withAnimation(.easeIn(duration: 0.15)) {
            for i in indices { cards[i].isLit = true }
        }

        // Auto-dim after window — penalty if not tapped
        litCardTimer = Timer.scheduledTimer(withTimeInterval: level.litWindow, repeats: false) { _ in
            DispatchQueue.main.async {
                let wasLit = self.cards.filter { $0.isLit }
                if !wasLit.isEmpty {
                    // Missed — apply penalty (1 life)
                    self.applyMissPenalty()
                }
                withAnimation { for i in self.cards.indices { self.cards[i].isLit = false } }
                // Schedule next round
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.scheduleLitCard(for: self.currentLevel)
                }
            }
        }
    }

    func handleCardTap(_ card: LightCard) {
        guard isGameRunning, !isGameOver,
              let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[idx].isLit {
            // ✅ Correct tap
            withAnimation { cards[idx].isLit = false }
            score += 1
            showPop(text: "+1", color: .neonGreen)

            // If all lit cards are tapped, schedule next immediately
            if cards.filter({ $0.isLit }).isEmpty {
                litCardTimer?.invalidate()
                litCardTimer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.scheduleLitCard(for: self.currentLevel)
                }
            }
        } else {
            // ❌ Wrong tap — lose a life
            applyMissPenalty()
            showPop(text: "−1 ❤️", color: .neonRed)
        }
    }

    private func applyMissPenalty() {
        guard lives > 0 else { return }
        lives -= 1
        if lives == 0 {
            endGame()
        }
    }

    private func endGame() {
        litCardTimer?.invalidate()
        litCardTimer = nil
        isGameRunning = false
        withAnimation { isGameOver = true }
        if score > storedHighScore { storedHighScore = score }
        for i in cards.indices { cards[i].isLit = false }
    }

    private func triggerLevelFlash(_ level: GameLevel) {
        flashLevel = level
        withAnimation(.easeIn(duration: 0.2)) { showLevelFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) { self.showLevelFlash = false }
        }
    }

    private func showPop(text: String, color: Color) {
        scorePopText = text
        scorePopColor = color
        scorePopOffset = 0
        scorePopOpacity = 1
        withAnimation(.easeOut(duration: 0.6)) {
            scorePopOffset = -50
            scorePopOpacity = 0
        }
    }
}
