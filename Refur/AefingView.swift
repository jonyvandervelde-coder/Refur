import SwiftUI

// MARK: - Color Palette

enum C {
    // Arctic Aurora — Nordic Frost Palette
    static let bgLight   = Color(red:0.94, green:0.98, blue:1.00)   // #F0F9FF Soft Ice Blue
    static let bgShade   = Color(red:0.88, green:0.95, blue:0.99)   // #E0F2FE Frost
    // Card surfaces — Snow White / Dark Slate
    static let card      = Color.white
    static let panel     = Color(red:0.06, green:0.09, blue:0.16)   // #0F172A Slate Dark
    static let inset     = Color(red:0.94, green:0.98, blue:1.00)   // icy inset
    static let border    = Color(red:0.88, green:0.95, blue:0.99)   // #E0F2FE icy border
    // Brand orange — Ember Fox accent
    static let orange    = Color(red:1.00, green:0.42, blue:0.00)   // #FF6B00
    static let orangeD   = Color(red:0.72, green:0.26, blue:0.00)
    // Gold
    static let gold      = Color(red:0.97, green:0.78, blue:0.12)
    static let goldDark  = Color(red:0.58, green:0.40, blue:0.02)
    // High-contrast slate text
    static let textDark  = Color(red:0.06, green:0.09, blue:0.16)   // #0F172A
    static let textMid   = Color(red:0.28, green:0.38, blue:0.52)
    // Text on dark surfaces
    static let cream     = Color.white
    static let creamMid  = Color(red:0.62, green:0.72, blue:0.88)
    // State
    static let correct   = Color(red:0.22, green:0.72, blue:0.38)
    static let correctD  = Color(red:0.08, green:0.36, blue:0.16)
    static let wrong     = Color(red:0.90, green:0.22, blue:0.18)
    static let wrongD    = Color(red:0.48, green:0.06, blue:0.06)
    // Tiles — Aurora Cyan / Electric Teal
    static let tile      = Color(red:0.02, green:0.71, blue:0.83)   // #06B6D4
    static let tileD     = Color(red:0.03, green:0.57, blue:0.70)   // #0891B2
    // Zone (drop boxes) — white with icy shadow
    static let zone      = Color.white
    static let zoneD     = Color(red:0.72, green:0.86, blue:0.93)
    static let zoneInset = Color(red:0.94, green:0.98, blue:1.00)
    // Sky / water (fox scene)
    static let skyTop    = Color(red:0.56, green:0.76, blue:0.94)
    static let skyBot    = Color(red:0.36, green:0.58, blue:0.86)
    static let water     = Color(red:0.20, green:0.42, blue:0.78)
    // Fox — Ember Fox Orange
    static let foxOrange = Color(red:1.00, green:0.42, blue:0.00)
    static let foxRed    = Color(red:0.82, green:0.26, blue:0.12)
    static let foxCream  = Color(red:0.98, green:0.93, blue:0.82)
    static let foxNose   = Color(red:0.16, green:0.10, blue:0.08)
}

// MARK: - Category pill colour map

private let catDefs: [(name: String, bg: Color, shadow: Color)] = [
    ("Nöfn",    Color(red:0.08,green:0.40,blue:0.46), Color(red:0.02,green:0.16,blue:0.22)),
    ("Dýr",     Color(red:0.70,green:0.30,blue:0.08), Color(red:0.34,green:0.12,blue:0.02)),
    ("Hlutir",  Color(red:0.20,green:0.36,blue:0.68), Color(red:0.08,green:0.14,blue:0.36)),
    ("Nýyrði",  Color(red:0.46,green:0.20,blue:0.68), Color(red:0.20,green:0.08,blue:0.36)),
    ("Sagnir",  Color(red:0.16,green:0.48,blue:0.26), Color(red:0.06,green:0.20,blue:0.10)),
    ("Matur",   Color(red:0.72,green:0.22,blue:0.36), Color(red:0.36,green:0.08,blue:0.14)),
    ("Náttúra", Color(red:0.10,green:0.48,blue:0.22), Color(red:0.04,green:0.20,blue:0.08)),
    ("Líkami",  Color(red:0.68,green:0.44,blue:0.10), Color(red:0.32,green:0.20,blue:0.04)),
    ("Klæði",   Color(red:0.56,green:0.14,blue:0.52), Color(red:0.26,green:0.06,blue:0.24)),
]

// MARK: - 3D Block

struct Block3D: View {
    let color: Color
    let shadow: Color
    var depth: CGFloat = 5
    var radius: CGFloat = 10

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius).fill(shadow).offset(y: depth)
            RoundedRectangle(cornerRadius: radius).fill(color)
            RoundedRectangle(cornerRadius: radius)
                .fill(LinearGradient(colors: [.white.opacity(0.32), .clear],
                                     startPoint: .top,
                                     endPoint: UnitPoint(x: 0.5, y: 0.44)))
            RoundedRectangle(cornerRadius: radius)
                .fill(LinearGradient(colors: [.clear, .black.opacity(0.14)],
                                     startPoint: UnitPoint(x: 0.5, y: 0.58),
                                     endPoint: .bottom))
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: radius))
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(shadow.opacity(0.80), lineWidth: 2)
        }
    }
}

// MARK: - Arcade Text

struct ArcadeText: View {
    let text: String
    let size: CGFloat
    var fill: Color = .white
    var outline: Color = .black
    var sw: CGFloat = 2

    init(_ text: String, size: CGFloat = 15, fill: Color = .white,
         outline: Color = .black, sw: CGFloat = 2) {
        self.text = text; self.size = size
        self.fill = fill; self.outline = outline; self.sw = sw
    }

    private var font: Font { .system(size: size, weight: .black, design: .rounded) }

    var body: some View {
        ZStack {
            Group {
                Text(text).offset(x: -sw, y: -sw)
                Text(text).offset(x:  sw, y: -sw)
                Text(text).offset(x: -sw, y:  sw)
                Text(text).offset(x:  sw, y:  sw)
            }
            .font(font).foregroundColor(outline)
            Text(text).font(font).foregroundColor(fill)
        }
    }
}

// MARK: - Custom Icons (no native iOS emoji)

/// Triangle shape for fox ears
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Custom drawn fox face — replaces 🦊 emoji
struct FoxFace: View {
    var size: CGFloat = 44
    var isDeceased: Bool = false

    var body: some View {
        ZStack {
            // Left ear
            Triangle()
                .fill(C.foxOrange)
                .frame(width: size * 0.30, height: size * 0.30)
                .offset(x: -size * 0.25, y: -size * 0.36)
            Triangle()
                .fill(C.foxRed)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x: -size * 0.25, y: -size * 0.32)
            // Right ear
            Triangle()
                .fill(C.foxOrange)
                .frame(width: size * 0.30, height: size * 0.30)
                .offset(x:  size * 0.25, y: -size * 0.36)
            Triangle()
                .fill(C.foxRed)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x:  size * 0.25, y: -size * 0.32)
            // Main face
            Circle()
                .fill(C.foxOrange)
                .frame(width: size, height: size)
            // Lower cream muzzle
            Ellipse()
                .fill(C.foxCream)
                .frame(width: size * 0.52, height: size * 0.42)
                .offset(y: size * 0.13)
            // Nose
            Ellipse()
                .fill(C.foxNose)
                .frame(width: size * 0.11, height: size * 0.08)
                .offset(y: size * 0.10)
            // Eyes
            if isDeceased {
                xEye.offset(x: -size * 0.17, y: -size * 0.09)
                xEye.offset(x:  size * 0.17, y: -size * 0.09)
            } else {
                // Left eye
                Circle().fill(C.foxNose)
                    .frame(width: size * 0.11, height: size * 0.11)
                    .offset(x: -size * 0.17, y: -size * 0.09)
                Circle().fill(.white)
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(x: -size * 0.14, y: -size * 0.12)
                // Right eye
                Circle().fill(C.foxNose)
                    .frame(width: size * 0.11, height: size * 0.11)
                    .offset(x:  size * 0.17, y: -size * 0.09)
                Circle().fill(.white)
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(x:  size * 0.20, y: -size * 0.12)
            }
        }
        .grayscale(isDeceased ? 0.75 : 0)
        .frame(width: size, height: size)
    }

    private var xEye: some View {
        let s = size * 0.13
        return ZStack {
            Rectangle()
                .fill(C.foxNose)
                .frame(width: s, height: s * 0.22)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(C.foxNose)
                .frame(width: s, height: s * 0.22)
                .rotationEffect(.degrees(-45))
        }
        .frame(width: s, height: s)
    }
}

/// Gold coin — replaces 🪙
struct CoinIcon: View {
    var size: CGFloat = 20
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [C.gold, C.goldDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Circle()
                .strokeBorder(C.goldDark, lineWidth: size * 0.08)
            Text("¢")
                .font(.system(size: size * 0.52, weight: .black, design: .rounded))
                .foregroundColor(C.goldDark)
        }
        .frame(width: size, height: size)
        .shadow(color: C.goldDark.opacity(0.50), radius: 2, x: 0, y: 1)
    }
}

/// Flame icon — replaces 🔥
struct FlameIcon: View {
    var size: CGFloat = 16
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(LinearGradient(
                colors: [Color(red:1.0, green:0.80, blue:0.10),
                         Color(red:0.95, green:0.38, blue:0.04)],
                startPoint: .top, endPoint: .bottom
            ))
            .shadow(color: C.orange.opacity(0.60), radius: 3, x: 0, y: 1)
    }
}

/// Heart tile — custom (no emoji)
struct HeartTile: View {
    var alive: Bool
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(alive ? C.wrong : C.zone)
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(alive ? C.wrongD : C.border, lineWidth: 1.5)
            Image(systemName: alive ? "heart.fill" : "heart")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundColor(alive ? .white : C.creamMid.opacity(0.50))
        }
        .frame(width: size, height: size)
        .shadow(color: alive ? C.wrongD.opacity(0.50) : .clear, radius: 3, x: 0, y: 2)
        .scaleEffect(alive ? 1.0 : 0.88)
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: alive)
    }
}

// MARK: - Nav Bar

struct AefingNavBar: View {
    @ObservedObject var game: GameState
    var onBack: () -> Void = {}

    @State private var coinScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 0) {
                backButton
                Spacer()
                titleBadge
                Spacer()
                statsRow
            }
            .padding(.horizontal, 14)

        }
        .onChange(of: game.coinBurst) { _ in
            guard game.coinBurst > 0 else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.40)) { coinScale = 1.5 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) { coinScale = 1.0 }
            }
        }
    }

    private var backButton: some View {
        Button(action: { onBack(); game.hapticTap() }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(C.cream)
                .frame(width: 38, height: 36)
                .background(Block3D(color: C.panel, shadow: C.zoneD, depth: 4))
        }
        .buttonStyle(.plain)
    }

    private var titleBadge: some View {
        ZStack {
            Text("Refur")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.black.opacity(0.35))
                .offset(y: 2)
            Text("Refur")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [C.orange, C.orangeD],
                    startPoint: .top, endPoint: .bottom
                ))
        }
        .shadow(color: C.orangeD.opacity(0.45), radius: 3, x: 0, y: 2)
    }

    private var statsRow: some View {
        HStack(spacing: 6) {
            // Coins
            HStack(spacing: 4) {
                CoinIcon(size: 16).scaleEffect(coinScale)
                Text("\(game.coins)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(C.gold)
                    .monospacedDigit()
            }
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 9).fill(C.card)
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(C.border, lineWidth: 1.5)))
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)

            // Streak
            HStack(spacing: 4) {
                FlameIcon(size: 13)
                Text("\(game.streak)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(C.orange)
                    .monospacedDigit()
            }
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 9).fill(C.card)
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(C.border, lineWidth: 1.5)))
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        }
    }

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(catDefs, id: \.name) { def in categoryPill(def) }
            }
            .padding(.horizontal, 14).padding(.bottom, 2)
        }
    }

    private func categoryPill(_ def: (name: String, bg: Color, shadow: Color)) -> some View {
        let selected = def.name == game.selectedCategory
        return Button(action: { game.loadQueue(category: def.name); game.hapticTap() }) {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white.opacity(0.80))
                }
                Text(def.name)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(selected ? .white : C.textDark)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Block3D(
                color: selected ? def.bg : C.zone,
                shadow: selected ? def.shadow : C.zoneD,
                depth: selected ? 4 : 3, radius: 10
            ))
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.70), value: selected)
    }
}

// MARK: - Fox Rescue Card

struct FoxCard: View {
    @ObservedObject var game: GameState
    @ObservedObject var session: SessionEngine

    @State private var foxY:   CGFloat = 0
    @State private var shakeX: CGFloat = 0
    @State private var sunkY:  CGFloat = 0

    var livesRemaining: Int { session.retriesLeft }
    private var isGameOver: Bool { session.phase == .sessionFailed || session.phase == .wordFailed }

    var body: some View {
        VStack(spacing: 0) {
            // Session header: progress
            HStack {
                Text(SessionEngine.landmark(at: session.activeIndex))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                Spacer()
                Text("Orð \(min(session.wordIndex + 1, SessionEngine.wordsPerSession))/\(SessionEngine.wordsPerSession)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: C.orangeD, radius: 0, x: 0, y: 1)
                Spacer()
                // Word dots
                HStack(spacing: 4) {
                    ForEach(0..<SessionEngine.wordsPerSession, id: \.self) { i in
                        Circle()
                            .fill(i < session.wordIndex ? Color.white : Color.white.opacity(0.30))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(LinearGradient(colors: [C.orange, C.orangeD], startPoint: .top, endPoint: .bottom))

            // 30-second countdown bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(C.orangeD.opacity(0.50)).frame(height: 5)
                    Rectangle()
                        .fill(timerBarColor)
                        .frame(width: max(0, geo.size.width * session.timerFraction), height: 5)
                        .animation(.linear(duration: 0.05), value: session.timerFraction)
                }
            }
            .frame(height: 5)

            // Ice scene
            ZStack {
                LinearGradient(colors: [C.skyTop, C.skyBot],
                               startPoint: .top, endPoint: .bottom)
                // Dark overlay when game over
                if isGameOver {
                    Color.black.opacity(0.40).transition(.opacity)
                }
                // Water layer
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [C.water.opacity(0.55), C.water],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(height: isGameOver ? 60 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.80), value: isGameOver)
                }
                // Ice ellipse
                Ellipse()
                    .fill(Color(red:0.44, green:0.68, blue:0.84).opacity(0.35))
                    .frame(width: 96, height: 12).offset(y: 24)
                Ellipse()
                    .fill(LinearGradient(colors: [.white, Color(red:0.82,green:0.93,blue:1.0)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 92, height: 16).offset(y: 21)

                // Custom fox face (no emoji)
                FoxFace(size: 42, isDeceased: isGameOver)
                    .offset(x: shakeX, y: foxY + sunkY - 8)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: sunkY)

                // "Diseased" skull overlay
                if isGameOver {
                    Text("×")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.70))
                        .offset(y: sunkY - 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 90)
            .clipped()
            .animation(.easeInOut(duration: 0.35), value: isGameOver)

            // Retries bar (session hearts)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Tilraunir")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(C.creamMid)
                    Text("\(session.retriesLeft) / \(SessionEngine.maxRetries)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(C.cream)
                }
                Spacer()
                HStack(spacing: 5) {
                    ForEach(0..<SessionEngine.maxRetries, id: \.self) { i in
                        HeartTile(alive: i < livesRemaining)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(C.panel)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(C.border, lineWidth: 2))
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
        .onChange(of: game.mistakeCount) { newVal in
            if game.isGameOver {
                // Fox sinks into water
                withAnimation(.spring(response: 0.55, dampingFraction: 0.70)) { sunkY = 38 }
            } else {
                // Fox dips and shakes on mistake
                withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) { foxY = 10 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.60)) { foxY = 0 }
                }
                let steps: [CGFloat] = [8, -7, 5, -4, 0]
                for (i, x) in steps.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                        withAnimation(.linear(duration: 0.06)) { shakeX = x }
                    }
                }
            }
        }
        .onChange(of: isGameOver) { over in
            if !over { withAnimation(.spring()) { sunkY = 0 } }
        }
    }

    private var timerBarColor: Color {
        let f = session.timerFraction
        if f > 0.50 { return C.correct }
        if f > 0.25 { return C.gold }
        return C.wrong
    }
}

// MARK: - Drop Zone

struct DropZone: View {
    let label: String
    var hint: String? = nil
    let sentence: String
    @Binding var word: String?
    var result: GameState.ZoneResult?
    var onDrop: (String) -> Void

    @State private var targeted     = false
    @State private var bounceScale: CGFloat = 1.0

    private var bgColor: Color {
        switch result {
        case .correct: return C.correct
        case .wrong:   return C.wrong
        case nil:      return targeted ? C.orange.opacity(0.28) : C.zone
        }
    }
    private var shadowColor: Color {
        switch result {
        case .correct: return C.correctD
        case .wrong:   return C.wrongD
        case nil:      return C.zoneD
        }
    }
    private var insetColor: Color {
        switch result {
        case .correct: return C.correctD.opacity(0.50)
        case .wrong:   return C.wrongD.opacity(0.50)
        case nil:      return C.zoneInset
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(hint ?? " ")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundColor(hint == nil ? .clear : (result == nil ? C.textMid.opacity(0.70) : .white.opacity(0.80)))
                .shadow(color: .black.opacity(0.40), radius: 0, x: 0, y: 1)
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(result == nil ? C.textDark : .white)
                .shadow(color: result == nil ? .clear : .black.opacity(0.40), radius: 0, x: 0, y: 1)

            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(shadowColor).offset(y: 3)
                RoundedRectangle(cornerRadius: 9).fill(bgColor)
                RoundedRectangle(cornerRadius: 7).fill(insetColor).padding(5)
                RoundedRectangle(cornerRadius: 9)
                    .fill(LinearGradient(colors: [.white.opacity(0.12), .clear],
                                         startPoint: .top, endPoint: .center))
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(shadowColor.opacity(0.70), lineWidth: 1.5)

                sentenceView
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .frame(minHeight: 62)
            .scaleEffect(bounceScale)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: bounceScale)
            .shadow(color: shadowColor.opacity(0.55), radius: 3, x: 0, y: 2)
            .onDrop(of: ["public.utf8-plain-text"], isTargeted: $targeted) { providers in
                providers.first?.loadDataRepresentation(
                    forTypeIdentifier: "public.utf8-plain-text"
                ) { data, _ in
                    guard let d = data, let s = String(data: d, encoding: .utf8) else { return }
                    DispatchQueue.main.async {
                        onDrop(s)
                        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { bounceScale = 1.08 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.60)) { bounceScale = 1.0 }
                        }
                    }
                }
                return true
            }
        }
        .onChange(of: result) { _ in
            guard result != nil else { return }
            withAnimation(.spring(response: 0.16, dampingFraction: 0.40)) { bounceScale = 1.10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) { bounceScale = 1.0 }
            }
        }
    }

    private var sentenceView: some View {
        let parts = sentence.components(separatedBy: "___")
        let before = parts.first ?? ""
        let after  = parts.count > 1 ? parts[1] : ""
        if let w = word, result == .correct {
            return (
                Text(before)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
                + Text(w)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(C.gold)
                + Text(after)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
            )
        } else if let w = word, result == .wrong {
            return (
                Text(before)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                + Text(w)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                + Text(after)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            )
        } else {
            return (
                Text(before)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textDark.opacity(0.75))
                + Text("___")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(C.zoneD.opacity(0.70))
                + Text(after)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textDark.opacity(0.75))
            )
        }
    }
}

// MARK: - Word Tile (Draggable)

struct WordTile: View {
    let word: String
    let isPlaced: Bool

    var body: some View {
        Text(word)
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundColor(isPlaced ? C.creamMid.opacity(0.40) : .white)
            .shadow(color: isPlaced ? .clear : C.tileD.opacity(0.70), radius: 0, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Block3D(
                color: isPlaced ? C.zone : C.tile,
                shadow: isPlaced ? C.zoneD : C.tileD,
                depth: isPlaced ? 2 : 5
            ))
            .contentShape(Rectangle())
            .onDrag {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                return NSItemProvider(object: word as NSString)
            }
            .opacity(isPlaced ? 0.55 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: isPlaced)
    }
}

// MARK: - Footer

struct AefingFooter: View {
    let correct: Int
    let total: Int
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            navButton(label: "Fyrra", icon: "chevron.left", leading: true,  action: onPrev)
            Spacer()
            scoreBadge
            Spacer()
            navButton(label: "Næsta", icon: "chevron.right", leading: false, action: onNext)
        }
    }

    private func navButton(label: String, icon: String, leading: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if leading  { Image(systemName: icon).font(.system(size: 10, weight: .black)) }
                Text(label).font(.system(size: 12, weight: .black, design: .rounded))
                if !leading { Image(systemName: icon).font(.system(size: 10, weight: .black)) }
            }
            .foregroundColor(C.cream)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Block3D(color: C.panel, shadow: C.zoneD, depth: 4))
        }
        .buttonStyle(.plain)
    }

    private var scoreBadge: some View {
        ArcadeText("\(correct) / \(total) rétt", size: 13,
                   fill: C.gold, outline: C.orangeD)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(C.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(C.border, lineWidth: 1.5))
            )
    }
}

// MARK: - Multiple Choice (indeclinable words)

struct MultiChoiceView: View {
    let word: WordEntry
    @ObservedObject var game: GameState
    var onCorrect: () -> Void
    var onWrong: () -> Void

    @State private var choices: [String] = []
    @State private var flashResult: String? = nil
    @State private var tappedChoice: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Text("Hvað þýðir orðið?")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(C.textMid)

            ForEach(choices, id: \.self) { choice in
                choiceButton(choice)
            }
        }
        .padding(.horizontal, 14)
        .onAppear { buildChoices() }
        .onChange(of: word.base) { _ in buildChoices(); flashResult = nil; tappedChoice = nil }
    }

    private func choiceButton(_ choice: String) -> some View {
        let wasTapped = tappedChoice == choice
        let bg: Color = {
            guard let r = flashResult, wasTapped else { return C.zone }
            return r == "correct" ? C.correct : C.wrong
        }()
        let bgShadow: Color = {
            guard let r = flashResult, wasTapped else { return C.zoneD }
            return r == "correct" ? C.correctD : C.wrongD
        }()
        return Button(action: { handleTap(choice) }) {
            Text(choice)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(wasTapped && flashResult != nil ? .white : C.textDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Block3D(color: bg, shadow: bgShadow, depth: 4, radius: 12))
        }
        .buttonStyle(.plain)
        .disabled(flashResult != nil)
        .animation(.spring(response: 0.22, dampingFraction: 0.60), value: flashResult)
    }

    private func handleTap(_ choice: String) {
        tappedChoice = choice
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if choice == word.translation {
            flashResult = "correct"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { onCorrect() }
        } else {
            flashResult = "wrong"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                flashResult = nil
                tappedChoice = nil
                onWrong()
            }
        }
    }

    private func buildChoices() {
        var pool: [String] = []
        let bank = WordBankStore.shared
        for (_, words) in bank.words {
            for entry in words where entry.translation != word.translation {
                pool.append(entry.translation)
            }
        }
        pool.shuffle()
        choices = ([word.translation] + Array(pool.prefix(3))).shuffled()
    }
}

// MARK: - Main Screen (navigation router)

struct AefingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = SessionEngine()
    @StateObject private var game    = GameState()
    @State private var profile       = UserProfile.current
    @State private var appScreen: AppScreen = UserProfile.isSetup ? .home : .profileSetup
    @State private var showSaveLimitBanner = false
    @StateObject private var savedWords = SavedWordsStore.shared

    enum AppScreen { case profileSetup, home, gameplay }

    private let zoneKeys   = ["nef",       "thol",       "thag",       "eig"]
    private let zoneLabels = ["Nefnifall", "Þolfall",    "Þágufall",   "Eignarfall"]
    private let zoneHints: [String?] = ["hér er ___", "um ___", "frá ___", "til ___"]

    var body: some View {
        Group {
            switch appScreen {
            case .profileSetup:
                ProfileSetupView { newProfile in
                    profile = newProfile
                    withAnimation { appScreen = .home }
                }

            case .home:
                HomeMapView(
                    session: session,
                    profile: profile,
                    onStartSession: { idx, daily in
                        game.loadQueue(category: game.selectedCategory)
                        session.startSession(idx, daily: daily)
                        withAnimation { appScreen = .gameplay }
                    },
                    onDismiss: { dismiss() }
                )

            case .gameplay:
                gameplayView
            }
        }
        // Word completed → advance session
        .onChange(of: game.correctCount) { count in
            guard count == 4, session.phase == .playing else { return }
            let bonus = Int(session.timeRemaining)
            if bonus > 0 {
                game.awardCoins(bonus)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            session.onWordCompleted()
            if session.phase == .playing { game.nextWord() }
        }
        // Per-word failure (3 wrong drops)
        .onChange(of: game.isGameOver) { over in
            guard over, session.phase == .playing else { return }
            session.onWordFailed()
        }
        // Session phase transitions
        .onChange(of: session.phase) { phase in
            if phase == .wordFailed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    guard session.phase == .wordFailed else { return }
                    game.restartWord()
                    session.resumeAfterWordFail()
                }
            }
        }
    }

    // MARK: Gameplay view

    private func tilePlacedFlags() -> [Bool] {
        let tiles = game.currentTiles
        var placedCount: [String: Int] = [:]
        for key in zoneKeys {
            if game.zoneResult[key] == .correct, let w = game.dropped[key] ?? nil {
                placedCount[w, default: 0] += 1
            }
        }
        var usedCount: [String: Int] = [:]
        var result: [Bool] = []
        for word in tiles {
            let used  = usedCount[word, default: 0]
            let total = placedCount[word, default: 0]
            let isP   = used < total
            result.append(isP)
            if isP { usedCount[word, default: 0] += 1 }
        }
        return result
    }

    private var gameplayView: some View {
        ZStack {
            LinearGradient(colors: [C.bgLight, C.bgShade], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                AefingNavBar(game: game, onBack: {
                    session.endSession()
                    withAnimation { appScreen = .home }
                })
                .padding(.top, 6)

                FoxCard(game: game, session: session)
                    .padding(.horizontal, 14)

                VStack(spacing: 2) {
                    ArcadeText(game.currentWord.base, size: 36,
                               fill: C.orange, outline: C.orangeD.opacity(0.80), sw: 2)
                    Text([game.currentWord.translation,
                          game.currentWord.plurality,
                          game.currentWord.article]
                        .filter { $0 != "-" }
                        .joined(separator: "  •  "))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textMid)
                }

                // ⭐ Vista orð button
                VStack(spacing: 4) {
                    if showSaveLimitBanner {
                        Text("Hámark 15 vista orð á viku")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(C.wrong)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    let alreadySaved = savedWords.isSaved(game.currentWord.base)
                    Button(action: {
                        game.hapticTap()
                        if alreadySaved {
                            savedWords.remove(game.currentWord.base)
                        } else if savedWords.canSaveMore {
                            savedWords.save(SavedWordEntry(
                                word: game.currentWord.base,
                                translation: game.currentWord.translation,
                                category: game.currentWord.category,
                                savedDate: SessionEngine.todayStr()
                            ))
                        } else {
                            withAnimation { showSaveLimitBanner = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showSaveLimitBanner = false }
                            }
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: alreadySaved ? "star.fill" : "star")
                                .font(.system(size: 12, weight: .bold))
                            Text(alreadySaved ? "Vistað" : "Vista orð")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundColor(alreadySaved ? C.gold : C.textMid)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(alreadySaved ? C.goldDark.opacity(0.15) : C.zone)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(alreadySaved ? C.goldDark.opacity(0.40) : C.zoneD,
                                                  lineWidth: 1.2))
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.70), value: alreadySaved)
                }

                if game.currentWord.isIndeclinable {
                    // Indeclinable: show multiple-choice meaning question
                    MultiChoiceView(
                        word: game.currentWord,
                        game: game,
                        onCorrect: { game.correctCount = 4 },
                        onWrong:   { game.multiChoiceWrong() }
                    )
                    .padding(.bottom, 2)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(Array(zip(zoneKeys.indices, zoneKeys)), id: \.0) { i, key in
                            let form = game.currentWord.form(forKey: key)
                            DropZone(
                                label: zoneLabels[i],
                                hint:  zoneHints[i],
                                sentence: form?.sentence ?? "___",
                                word: Binding(get: { game.dropped[key] ?? nil }, set: { _ in }),
                                result: game.zoneResult[key],
                                onDrop: { word in game.drop(word: word, intoKey: key) }
                            )
                        }
                    }
                    .padding(.horizontal, 14)

                    Text("— Dragðu orðin —")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(C.textMid.opacity(0.55))

                    let tiles      = game.currentTiles
                    let tilePlaced = tilePlacedFlags()
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            if tiles.count > 0 { WordTile(word: tiles[0], isPlaced: tilePlaced[0]) }
                            if tiles.count > 1 { WordTile(word: tiles[1], isPlaced: tilePlaced[1]) }
                        }
                        HStack(spacing: 8) {
                            if tiles.count > 2 { WordTile(word: tiles[2], isPlaced: tilePlaced[2]) }
                            if tiles.count > 3 { WordTile(word: tiles[3], isPlaced: tilePlaced[3]) }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 2)
                }

                // Hide Fyrra/Næsta in session mode — session controls word flow
                if session.phase == .idle {
                    AefingFooter(
                        correct: game.correctCount, total: 4,
                        onPrev: { game.prevWord() },
                        onNext: { game.nextWord() }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                } else {
                    Spacer().frame(height: 8)
                }
            }

            // Session complete overlay
            if session.phase == .sessionComplete {
                SessionCompleteOverlay(session: session, profile: profile) {
                    session.endSession()
                    withAnimation { appScreen = .home }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }

            // Session failed overlay
            if session.phase == .sessionFailed {
                SessionFailedOverlay(session: session) {
                    game.restartWord()
                    session.retrySession()
                } onQuit: {
                    session.endSession()
                    withAnimation { appScreen = .home }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.phase)
    }
}

#Preview {
    AefingView()
}
