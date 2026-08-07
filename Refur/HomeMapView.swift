import SwiftUI

// MARK: - Profile Setup View

struct ProfileSetupView: View {
    var onComplete: (UserProfile) -> Void

    @State private var nickname    = ""
    @State private var ageBracket  = "18_plus"
    @State private var colorIdx    = 0
    @FocusState private var nickFocused: Bool

    private let brackets = [
        ("under18","Undir 18"), ("18_25","18–25"), ("26_35","26–35"), ("36_plus","36+")
    ]
    private var canSave: Bool { !nickname.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            LinearGradient(colors: [C.bgLight, C.bgShade], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {

                    VStack(spacing: 6) {
                        ArcadeText("Refur", size: 40, fill: C.orange, outline: C.orangeD, sw: 2.5)
                        Text("Búðu til prófílinn þinn")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(C.textMid)
                    }
                    .padding(.top, 44)

                    // Avatar preview
                    ZStack {
                        Circle()
                            .fill(UserProfile.avatarColors[colorIdx])
                            .frame(width: 80, height: 80)
                            .shadow(color: UserProfile.avatarColors[colorIdx].opacity(0.45), radius: 8, x: 0, y: 4)
                        Text(nickname.isEmpty ? "?" : String(nickname.prefix(1)).uppercased())
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }

                    // Nickname field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nafnið þitt")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(C.textDark)
                        TextField("Sláðu inn gælunafn", text: $nickname)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(C.zone))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(C.zoneD.opacity(0.40), lineWidth: 1.5))
                            .focused($nickFocused)
                            .onSubmit { nickFocused = false }
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 28)

                    // Avatar color picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Litur")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(C.textDark)
                            .padding(.horizontal, 28)
                        HStack(spacing: 16) {
                            ForEach(0..<UserProfile.avatarColors.count, id: \.self) { i in
                                Button {
                                    withAnimation(.spring(response: 0.22)) { colorIdx = i }
                                } label: {
                                    Circle()
                                        .fill(UserProfile.avatarColors[i])
                                        .frame(width: 38, height: 38)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: colorIdx == i ? 3 : 0))
                                        .scaleEffect(colorIdx == i ? 1.15 : 1.0)
                                        .shadow(color: UserProfile.avatarColors[i].opacity(0.45), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 28)
                    }

                    // Age bracket
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aldursbil")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(C.textDark)
                        HStack(spacing: 8) {
                            ForEach(brackets, id: \.0) { code, label in
                                Button { ageBracket = code } label: {
                                    Text(label)
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundColor(ageBracket == code ? .white : C.textDark)
                                        .padding(.horizontal, 14).padding(.vertical, 9)
                                        .background(Block3D(
                                            color:  ageBracket == code ? C.orange : C.zone,
                                            shadow: ageBracket == code ? C.orangeD : C.zoneD,
                                            depth: 3
                                        ))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 28)

                    // Save button
                    Button {
                        let p = UserProfile(
                            nickname: nickname.trimmingCharacters(in: .whitespaces),
                            ageBracket: ageBracket,
                            avatarColorIndex: colorIdx
                        )
                        p.save()
                        onComplete(p)
                    } label: {
                        Text("Hefja!")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Block3D(
                                color:  canSave ? C.correct : C.zone,
                                shadow: canSave ? C.correctD : C.zoneD,
                                depth: 5
                            ))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 44)
                }
            }
        }
    }
}

// MARK: - Home / Map View

struct HomeMapView: View {
    @ObservedObject var session: SessionEngine
    var profile: UserProfile
    var onStartSession: (Int, Bool) -> Void
    var onDismiss: () -> Void

    @State private var showProfileSheet = false
    @State private var showLoginScreen  = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [C.bgLight, C.bgShade], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        profileCard
                        streakRow
                        Divider().padding(.horizontal, 20)
                        sessionGrid
                    }
                    .padding(.bottom, 44)
                }
            }

            if showProfileSheet {
                ProfileDetailView(
                    session: session,
                    onOpenLogin: { showLoginScreen = true },
                    onDismiss:   { withAnimation { showProfileSheet = false } }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }

            if showLoginScreen {
                LoginView { acc in
                    withAnimation { showLoginScreen = false }
                } onDismiss: {
                    withAnimation { showLoginScreen = false }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showProfileSheet)
        .animation(.easeInOut(duration: 0.28), value: showLoginScreen)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(C.cream)
                    .frame(width: 36, height: 34)
                    .background(Block3D(color: C.panel, shadow: C.zoneD, depth: 3))
            }
            .buttonStyle(.plain)

            Spacer()
            ArcadeText("Refur", size: 22, fill: C.orange, outline: C.orangeD, sw: 1.5)
            Spacer()

            HStack(spacing: 4) {
                CoinIcon(size: 14)
                Text("\(UserDefaults.standard.integer(forKey: "gs.coins"))")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(C.gold)
            }
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(C.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(C.border, lineWidth: 1.5))
            )
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
    }

    // MARK: Profile card

    private var profileCard: some View {
        Button { showProfileSheet = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(profile.avatarColor)
                        .frame(width: 52, height: 52)
                        .shadow(color: profile.avatarColor.opacity(0.40), radius: 5, x: 0, y: 3)
                    Text(profile.initial)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.nickname)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(C.textDark)
                    HStack(spacing: 4) {
                        Text("Stig \(session.unlockedCount)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(C.textMid)
                        if UserAccount.current != nil {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(C.correct)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    VStack(spacing: 2) {
                        FlameIcon(size: 22)
                        Text("\(session.streak)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(C.orange)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(C.textMid.opacity(0.40))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(C.zone)
                    .shadow(color: C.zoneD.opacity(0.35), radius: 5, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: Streak row (Mon–Sun current week)

    private let weekLabels = ["Má", "Þr", "Mi", "Fi", "Fö", "La", "Su"]

    private var streakRow: some View {
        let today = SessionEngine.todayStr()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Þessi vika")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(C.textMid)
            HStack(spacing: 0) {
                ForEach(Array(session.currentWeekDays.enumerated()), id: \.offset) { i, entry in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(entry.played ? C.correct
                                      : entry.date == today ? C.orange.opacity(0.20)
                                      : C.zoneD.opacity(0.22))
                                .frame(width: 28, height: 28)
                            if entry.played {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                            } else if entry.date == today {
                                Circle()
                                    .strokeBorder(C.orange, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        Text(weekLabels[i])
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(entry.date == today ? C.orange : C.textMid.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(C.zone)
                .shadow(color: C.zoneD.opacity(0.25), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }

    // MARK: Daily card

    private var dailyCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Dagleg Æfing")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(C.textDark)
                    Text("\(session.dailyWordsCompleted)/\(SessionEngine.dailyWordLimit) orð í dag")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(C.textMid)
                }
                Spacer()
                if session.isDailyDone {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(C.correct)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(C.zoneD.opacity(0.22))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [C.correct, C.correct.opacity(0.65)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(0, geo.size.width * session.dailyFraction), height: 10)
                        .animation(.spring(response: 0.40), value: session.dailyFraction)
                }
            }
            .frame(height: 10)

            if !session.isDailyDone {
                Button { onStartSession(0, true) } label: {
                    HStack {
                        Text("Hefja daglegu æfingu")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Block3D(color: C.orange, shadow: C.orangeD, depth: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(C.zone)
                .shadow(color: C.zoneD.opacity(0.25), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }

    // MARK: Session grid

    private var sessionGrid: some View {
        let total    = max(session.unlockedCount + 2, 8)
        let nodeH: CGFloat  = 96
        let nodeW: CGFloat  = 82
        // Duolingo-style wave: left → center → right → center → left …
        let xFracs: [CGFloat] = [0.24, 0.50, 0.76, 0.50]

        return GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {

                // Dashed path connecting node centers
                Canvas { ctx, size in
                    var path = Path()
                    for i in 0..<total {
                        let cx = size.width * xFracs[i % xFracs.count]
                        let cy = CGFloat(i) * nodeH + nodeH * 0.5
                        if i == 0 { path.move(to: CGPoint(x: cx, y: cy)) }
                        else      { path.addLine(to: CGPoint(x: cx, y: cy)) }
                    }
                    ctx.stroke(
                        path,
                        with: .color(C.zoneD.opacity(0.80)),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round,
                                           lineJoin: .round, dash: [10, 8])
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Nodes positioned along the zigzag
                ForEach(0..<total, id: \.self) { idx in
                    let cx   = w * xFracs[idx % xFracs.count]
                    let cy   = CGFloat(idx) * nodeH + nodeH * 0.5
                    let icon = SessionEngine.nodeIcon(at: idx)
                    SessionMapNode(number: idx + 1, icon: icon, state: session.nodeState(at: idx)) {
                        if session.nodeState(at: idx) != .locked {
                            onStartSession(idx, false)
                        }
                    }
                    .frame(width: nodeW)
                    .position(x: cx, y: cy)
                }
            }
        }
        .frame(height: CGFloat(total) * nodeH + 40)
        .padding(.horizontal, 12)
    }

    private func dayLabel(_ str: String) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: str) else { return "" }
        let out = DateFormatter(); out.dateFormat = "EEE"
        out.locale = Locale(identifier: "is_IS")
        return String(out.string(from: d).prefix(2)).uppercased()
    }
}

// MARK: - Session Map Node

struct SessionMapNode: View {
    let number: Int
    let icon:   String
    let state:  SessionEngine.NodeState
    let onTap:  () -> Void

    private var fillColor: Color {
        switch state { case .done: return C.correct; case .open: return C.orange; case .locked: return C.zone }
    }
    private var shadowColor: Color {
        switch state { case .done: return C.correctD; case .open: return C.orangeD; case .locked: return C.zoneD.opacity(0.40) }
    }

    var body: some View {
        Button(action: { if state != .locked { onTap() } }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(shadowColor).frame(width: 58, height: 58).offset(y: 4)
                    Circle().fill(fillColor).frame(width: 58, height: 58)
                        .overlay(nodeIcon)
                }
                Text(SessionEngine.landmark(at: number - 1))
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(state == .locked ? C.textMid.opacity(0.35) : C.textDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .opacity(state == .locked ? 0.55 : 1.0)
    }

    @ViewBuilder private var nodeIcon: some View {
        switch state {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .black)).foregroundColor(.white)
        case .open:
            Text(icon)
                .font(.system(size: 22))
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: 16)).foregroundColor(C.zoneD.opacity(0.55))
        }
    }
}

// MARK: - Session Result Overlays

struct SessionCompleteOverlay: View {
    @ObservedObject var session: SessionEngine
    var profile: UserProfile
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.60).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("🎉")
                    .font(.system(size: 56))
                ArcadeText("Fundur lokið!", size: 28, fill: C.gold, outline: C.goldDark, sw: 2)
                Text("Þú laukst við \(SessionEngine.wordsPerSession) orð!")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                // Streak display
                HStack(spacing: 10) {
                    FlameIcon(size: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(session.streak) daga röð")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(C.orange)
                        if session.longestStreak > 1 {
                            Text("Lengsta röð: \(session.longestStreak)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.60))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(C.card))

                Button(action: onContinue) {
                    Text("Áfram")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Block3D(color: C.correct, shadow: C.correctD, depth: 5))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(C.panel)
                    .shadow(color: .black.opacity(0.50), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }
}

struct SessionFailedOverlay: View {
    @ObservedObject var session: SessionEngine
    var onRetry: () -> Void
    var onQuit:  () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                FoxFace(size: 64, isDeceased: true)
                ArcadeText("Tíminn rann út", size: 24, fill: C.wrong, outline: C.wrongD, sw: 2)
                Text("Þú hafnir öllum þremur tilraunum.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)

                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .black))
                        Text("Reyna aftur")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Block3D(color: C.orange, shadow: C.orangeD, depth: 5))
                }
                .buttonStyle(.plain)

                Button(action: onQuit) {
                    Text("Hætta við")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(C.panel)
                    .shadow(color: .black.opacity(0.50), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }
}

// MARK: - Profile Detail Sheet

struct ProfileDetailView: View {
    @ObservedObject var session: SessionEngine
    var onOpenLogin: () -> Void
    var onDismiss: () -> Void
    @StateObject private var savedWords = SavedWordsStore.shared
    @State private var account = UserAccount.current

    private let profile = UserProfile.current

    var body: some View {
        ZStack {
            C.bgLight.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Loka") { onDismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(C.orange)
                        .padding(.trailing, 20)
                }
                .frame(height: 52)
                .background(C.bgLight)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        accountSection
                        savedWordsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 44)
                }
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(profile.avatarColor)
                    .frame(width: 64, height: 64)
                    .shadow(color: profile.avatarColor.opacity(0.40), radius: 6, x: 0, y: 3)
                Text(profile.initial)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.nickname)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(C.textDark)
                if let acc = account {
                    Label(acc.email, systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(C.correct).lineLimit(1)
                }
            }
            Spacer()
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    FlameIcon(size: 16)
                    Text("\(session.streak)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(C.orange)
                }
                Text("Röð")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textMid)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(C.zone)
            .shadow(color: C.zoneD.opacity(0.25), radius: 5, x: 0, y: 3))
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reikningur")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(C.textMid)
            if let acc = account {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20)).foregroundColor(C.correct)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Skráður inn")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(C.textDark)
                        Text(acc.email)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(C.textMid).lineLimit(1)
                    }
                    Spacer()
                    Button("Útskrá") {
                        UserAccount.logout()
                        account = nil
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(C.wrong)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(C.zone))
            } else {
                Button { onOpenLogin() } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Skrá inn / stofna reikning")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Block3D(color: C.orange, shadow: C.orangeD, depth: 4, radius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var savedWordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Vistaðar orð")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(C.textMid)
                Spacer()
                Text("\(savedWords.thisWeekCount)/\(SavedWordsStore.maxPerWeek) þ.v.")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textMid)
            }
            if savedWords.entries.isEmpty {
                Text("Engar vistaðar orð. Ýttu á ⭐ meðan þú æfir.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textMid)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(RoundedRectangle(cornerRadius: 12).fill(C.zone.opacity(0.60)))
            } else {
                ForEach(savedWords.entries) { entry in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.word)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(C.textDark)
                            Text(entry.translation)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(C.textMid)
                        }
                        Spacer()
                        Text(entry.category)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(C.tile))
                        Button { savedWords.remove(entry.word) } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(C.textMid)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(C.zoneD.opacity(0.30)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(C.zone))
                }
            }
        }
    }
}

// MARK: - Login / Sign-up View

struct LoginView: View {
    var onLogin: (UserAccount) -> Void
    var onDismiss: () -> Void

    @State private var email    = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var errorMsg = ""
    @FocusState private var focusedField: LoginField?

    enum LoginField { case email, password }

    private var canSubmit: Bool { email.contains("@") && password.count >= 6 }

    var body: some View {
        ZStack {
            C.bgLight.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                ArcadeText("Refur", size: 42, fill: C.orange, outline: C.orangeD, sw: 2.5)

                Text(isSignUp ? "Nýr reikningur" : "Velkominn aftur!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(C.textDark)

                VStack(spacing: 12) {
                    TextField("Netfang", text: $email)
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundColor(C.textDark)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(focusedField == .email ? C.orange.opacity(0.60) : C.zoneD.opacity(0.40), lineWidth: 1.5))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    SecureField("Lykilorð (6+ stafir)", text: $password)
                        .focused($focusedField, equals: .password)
                        .foregroundColor(C.textDark)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(focusedField == .password ? C.orange.opacity(0.60) : C.zoneD.opacity(0.40), lineWidth: 1.5))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    if !errorMsg.isEmpty {
                        Text(errorMsg)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(C.wrong)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)

                Button {
                    guard canSubmit else {
                        errorMsg = "Sláðu inn gilt netfang og lykilorð (6+ stafir)"
                        return
                    }
                    let acc = UserAccount(email: email.lowercased())
                    acc.save()
                    onLogin(acc)
                } label: {
                    Text(isSignUp ? "Stofna reikning" : "Skrá inn")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Block3D(
                            color:  canSubmit ? C.orange : C.zone,
                            shadow: canSubmit ? C.orangeD : C.zoneD,
                            depth: 5
                        ))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .padding(.horizontal, 28)

                Button { isSignUp.toggle(); errorMsg = "" } label: {
                    Text(isSignUp
                         ? "Ertu þegar með reikning? Skrá inn"
                         : "Engan reikning? Stofna hér")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(C.textMid)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Sleppa") { onDismiss() }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(C.textMid.opacity(0.55))
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .email
            }
        }
    }
}
