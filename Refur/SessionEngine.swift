import Foundation
import SwiftUI
import Combine

// MARK: - User Profile

struct UserProfile: Codable {
    var nickname: String
    var ageBracket: String       // "under18" | "18_25" | "26_35" | "36_plus"
    var avatarColorIndex: Int    // 0‥4

    private static let udKey = "refur.profile.v1"

    static var current: UserProfile {
        guard let d = UserDefaults.standard.data(forKey: udKey),
              let p = try? JSONDecoder().decode(UserProfile.self, from: d)
        else { return UserProfile(nickname: "", ageBracket: "18_plus", avatarColorIndex: 0) }
        return p
    }

    static var isSetup: Bool {
        !current.nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static let avatarColors: [Color] = [
        Color(red: 0.91, green: 0.44, blue: 0.00), // orange
        Color(red: 0.20, green: 0.60, blue: 0.90), // blue
        Color(red: 0.24, green: 0.72, blue: 0.28), // green
        Color(red: 0.60, green: 0.28, blue: 0.80), // purple
        Color(red: 0.85, green: 0.22, blue: 0.30), // red
    ]

    var avatarColor: Color {
        UserProfile.avatarColors[min(avatarColorIndex, UserProfile.avatarColors.count - 1)]
    }
    var initial: String { String(nickname.prefix(1)).uppercased() }

    func save() {
        if let d = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(d, forKey: UserProfile.udKey)
        }
    }
}

// MARK: - Session Engine

final class SessionEngine: ObservableObject {

    static let wordsPerSession  = 6
    static let secondsPerWord: Double = 20
    static let maxRetries       = 3
    static let dailyWordLimit   = 6

    static let landmarks: [String] = [
        "Staðarskáli", "Geysir", "Gullfoss", "Þingvellir",
        "Akureyri", "Vík", "Jökulsárlón", "Snæfellsjökull",
        "Landmannalaugar", "Mývatn", "Dettifoss", "Skaftafell",
        "Húsavík", "Ísafjörður", "Borgarnes", "Selfoss",
        "Faxaflói", "Skógar", "Stykkishólmur", "Þórsmörk"
    ]

    static func landmark(at index: Int) -> String {
        guard index >= 0, index < landmarks.count else { return "Fundur \(index + 1)" }
        return landmarks[index]
    }

    enum Phase: Equatable { case idle, playing, wordFailed, sessionComplete, sessionFailed }

    // MARK: Map state
    @Published var unlockedCount: Int
    @Published var completedIndices: Set<Int>

    // MARK: Daily
    @Published var dailyWordsCompleted: Int

    // MARK: Streak (owned here so HomeMapView observes one object)
    @Published var streak: Int
    @Published var longestStreak: Int
    @Published private(set) var playedDates: Set<String>

    // MARK: Active session
    @Published var activeIndex: Int = -1
    @Published var wordIndex: Int = 0
    @Published var retriesLeft: Int = SessionEngine.maxRetries
    @Published var timeRemaining: Double = SessionEngine.secondsPerWord
    @Published var phase: Phase = .idle
    @Published var isDailyMode: Bool = false

    private var timerBag: AnyCancellable?

    init() {
        let today = Self.todayStr()
        let savedDay = UserDefaults.standard.string(forKey: "se.dailyDate") ?? ""
        dailyWordsCompleted = savedDay == today
            ? UserDefaults.standard.integer(forKey: "se.dailyWords") : 0
        if savedDay != today {
            UserDefaults.standard.set(today, forKey: "se.dailyDate")
            UserDefaults.standard.set(0,     forKey: "se.dailyWords")
        }
        unlockedCount    = max(1, UserDefaults.standard.integer(forKey: "se.unlocked"))
        completedIndices = Set((UserDefaults.standard.array(forKey: "se.completed") as? [Int]) ?? [])
        streak       = UserDefaults.standard.integer(forKey: "se.streak")
        longestStreak = UserDefaults.standard.integer(forKey: "se.longest")
        playedDates  = Set((UserDefaults.standard.array(forKey: "se.playedDates") as? [String]) ?? [])
        refreshStreak()
    }

    // MARK: Session control

    func startSession(_ index: Int, daily: Bool = false) {
        activeIndex  = index
        isDailyMode  = daily
        wordIndex    = 0
        retriesLeft  = Self.maxRetries
        phase        = .playing
        startTimer()
    }

    func onWordCompleted() {
        stopTimer()
        wordIndex += 1
        if isDailyMode {
            dailyWordsCompleted = min(dailyWordsCompleted + 1, Self.dailyWordLimit)
            UserDefaults.standard.set(dailyWordsCompleted, forKey: "se.dailyWords")
        }
        if wordIndex >= Self.wordsPerSession {
            finishSession()
        } else {
            retriesLeft = Self.maxRetries
            phase = .playing
            startTimer()
        }
    }

    func onWordFailed() {
        guard phase == .playing else { return }
        stopTimer()
        retriesLeft -= 1
        phase = retriesLeft <= 0 ? .sessionFailed : .wordFailed
    }

    func resumeAfterWordFail() {
        guard phase == .wordFailed else { return }
        phase = .playing
        startTimer()
    }

    func retrySession() {
        wordIndex   = 0
        retriesLeft = Self.maxRetries
        phase       = .playing
        startTimer()
    }

    func endSession() {
        stopTimer()
        activeIndex = -1
        phase       = .idle
    }

    // MARK: Timer

    func startTimer() {
        timerBag?.cancel()
        timeRemaining = Self.secondsPerWord
        timerBag = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, phase == .playing else { return }
                timeRemaining = max(0, timeRemaining - 0.05)
                if timeRemaining == 0 { onWordFailed() }
            }
    }

    private func stopTimer() { timerBag?.cancel() }

    // MARK: Finish

    private func finishSession() {
        phase = .sessionComplete
        completedIndices.insert(activeIndex)
        UserDefaults.standard.set(Array(completedIndices), forKey: "se.completed")
        let next = activeIndex + 1
        if next >= unlockedCount {
            unlockedCount = next + 1
            UserDefaults.standard.set(unlockedCount, forKey: "se.unlocked")
        }
        if isDailyMode { recordToday() }
    }

    // MARK: Streak

    func recordToday() {
        let today = Self.todayStr()
        guard !playedDates.contains(today) else { return }
        playedDates.insert(today)
        UserDefaults.standard.set(Array(playedDates), forKey: "se.playedDates")
        let yesterday = Self.dateStr(daysAgo: 1)
        streak = playedDates.contains(yesterday) ? streak + 1 : 1
        longestStreak = max(longestStreak, streak)
        UserDefaults.standard.set(streak,        forKey: "se.streak")
        UserDefaults.standard.set(longestStreak, forKey: "se.longest")
    }

    private func refreshStreak() {
        let today     = Self.todayStr()
        let yesterday = Self.dateStr(daysAgo: 1)
        if !playedDates.contains(today) && !playedDates.contains(yesterday) && streak > 0 {
            streak = 0
            UserDefaults.standard.set(0, forKey: "se.streak")
        }
    }

    var last7Days: [(date: String, played: Bool)] {
        (0..<7).reversed().map { n in
            let d = Self.dateStr(daysAgo: n)
            return (d, playedDates.contains(d))
        }
    }

    // Current ISO week Mon→Sun
    var currentWeekDays: [(date: String, played: Bool)] {
        let cal = Calendar(identifier: .iso8601)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let monday = cal.date(from: cal.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return (0..<7).map { n in
            let d = cal.date(byAdding: .day, value: n, to: monday)!
            let str = fmt.string(from: d)
            return (str, playedDates.contains(str))
        }
    }

    static func todayStr() -> String { dateStr(daysAgo: 0) }
    static func dateStr(daysAgo: Int) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    // MARK: Computed

    var isDailyDone: Bool  { dailyWordsCompleted >= Self.dailyWordLimit }
    var dailyFraction: Double { Double(dailyWordsCompleted) / Double(Self.dailyWordLimit) }
    var timerFraction: Double { timeRemaining / Self.secondsPerWord }

    func nodeState(at index: Int) -> NodeState {
        if completedIndices.contains(index) { return .done }
        if index < unlockedCount            { return .open }
        return .locked
    }

    enum NodeState { case done, open, locked }
}

// MARK: - User Account (local auth — Supabase-ready)

struct UserAccount: Codable {
    var email: String

    private static let udKey = "refur.account.v1"

    static var current: UserAccount? {
        guard let d = UserDefaults.standard.data(forKey: udKey),
              let a = try? JSONDecoder().decode(UserAccount.self, from: d)
        else { return nil }
        return a
    }

    func save() {
        if let d = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(d, forKey: UserAccount.udKey)
        }
    }

    static func logout() {
        UserDefaults.standard.removeObject(forKey: udKey)
    }
}

// MARK: - Saved Words Store (max 15 / calendar week)

struct SavedWordEntry: Codable, Identifiable {
    var id: String { word }
    let word: String
    let translation: String
    let category: String
    let savedDate: String   // "yyyy-MM-dd"
}

final class SavedWordsStore: ObservableObject {
    static let shared = SavedWordsStore()
    static let maxPerWeek = 15
    private static let udKey = "refur.savedWords.v2"

    @Published var entries: [SavedWordEntry] = []

    private init() { load() }

    var thisWeekCount: Int {
        let start = weekStart()
        return entries.filter { $0.savedDate >= start }.count
    }

    var canSaveMore: Bool { thisWeekCount < Self.maxPerWeek }

    @discardableResult
    func save(_ entry: SavedWordEntry) -> Bool {
        guard canSaveMore, !isSaved(entry.word) else { return false }
        entries.append(entry)
        persist()
        return true
    }

    func isSaved(_ word: String) -> Bool { entries.contains { $0.word == word } }

    func remove(_ word: String) { entries.removeAll { $0.word == word }; persist() }

    private func weekStart() -> String {
        let cal = Calendar(identifier: .iso8601)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return fmt.string(from: start)
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: Self.udKey),
              let e = try? JSONDecoder().decode([SavedWordEntry].self, from: d)
        else { return }
        entries = e
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(d, forKey: Self.udKey)
        }
    }
}
