import Foundation
import UIKit
import SwiftUI

// MARK: - Word Model

struct WordEntry: Identifiable, Codable {
    var id: String { base }
    let base: String
    let translation: String
    let category: String
    let gender: String
    let plurality: String
    let article: String

    struct Form: Codable {
        let word: String
        let sentence: String
    }

    let nefnifall:  Form
    let tholfall:   Form
    let thagufall:  Form
    let eignarfall: Form

    var allForms: [Form] { [nefnifall, tholfall, thagufall, eignarfall] }

    var isIndeclinable: Bool {
        nefnifall.word == tholfall.word &&
        tholfall.word  == thagufall.word &&
        thagufall.word == eignarfall.word
    }

    func isCorrect(_ dropped: String, forKey key: String) -> Bool {
        switch key {
        case "nef":  return dropped == nefnifall.word
        case "thol": return dropped == tholfall.word
        case "thag": return dropped == thagufall.word
        case "eig":  return dropped == eignarfall.word
        default: return false
        }
    }

    func form(forKey key: String) -> Form? {
        switch key {
        case "nef":  return nefnifall
        case "thol": return tholfall
        case "thag": return thagufall
        case "eig":  return eignarfall
        default: return nil
        }
    }
}

// MARK: - Word Bank (JSON-backed)

private struct WordBankJSON: Codable {
    let categories: [String]
    let words: [String: [WordEntry]]
}

struct WordBankStore {
    let categories: [String]
    let words: [String: [WordEntry]]

    static let shared: WordBankStore = {
        guard
            let url  = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let db   = try? JSONDecoder().decode(WordBankJSON.self, from: data)
        else {
            // Minimal fallback so the app never crashes without the file
            let stub = WordEntry(
                base: "köttur", translation: "cat",
                category: "Dýr", gender: "kk", plurality: "eintala", article: "án greinis",
                nefnifall:  .init(word: "köttur", sentence: "___ er hér."),
                tholfall:   .init(word: "kött",   sentence: "Ég sé ___."),
                thagufall:  .init(word: "ketti",  sentence: "Hann gefur ___ mat."),
                eignarfall: .init(word: "kattar", sentence: "Þetta er heimili ___.")
            )
            return WordBankStore(categories: ["Dýr"], words: ["Dýr": [stub]])
        }
        return WordBankStore(categories: db.categories, words: db.words)
    }()
}

// MARK: - Node Progress

enum NodeState: String, Codable {
    case locked, inProgress, completed, mastered
}

// MARK: - GameState

final class GameState: ObservableObject {

    // Persisted state
    @Published var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: "gs.coins") }
    }
    @Published var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: "gs.streak") }
    }

    // Session state
    @Published var selectedCategory: String = "Dýr"
    @Published var currentWord: WordEntry
    @Published var currentTiles: [String] = []
    @Published var dropped: [String: String?]  = ["nef": nil, "thol": nil, "thag": nil, "eig": nil]
    @Published var zoneResult: [String: ZoneResult] = [:]
    @Published var mistakeCount: Int = 0
    @Published var correctCount: Int = 0
    @Published var coinBurst: Int = 0
    @Published var dailyWordsCompleted: Int = 0
    @Published var isDaily: Bool = false

    let maxMistakes = 3
    let dailyWordTarget = 5

    enum ZoneResult { case correct, wrong }

    // Haptics
    private let impactMed   = UIImpactFeedbackGenerator(style: .medium)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let notify      = UINotificationFeedbackGenerator()

    private var wordQueue: [WordEntry] = []
    private var queueIndex: Int = 0

    private let store = WordBankStore.shared

    private var lastPlayedEpoch: Double {
        get { UserDefaults.standard.double(forKey: "gs.lastPlayed") }
        set { UserDefaults.standard.set(newValue, forKey: "gs.lastPlayed") }
    }

    var categories: [String] { store.categories }

    init() {
        coins  = UserDefaults.standard.integer(forKey: "gs.coins")
        streak = UserDefaults.standard.integer(forKey: "gs.streak")
        let first = store.words["Dýr"]?.first ?? store.words.values.first!.first!
        currentWord = first
        currentTiles = first.allForms.map(\.word).shuffled()
        impactMed.prepare(); impactLight.prepare(); notify.prepare()
        refreshStreak()
        loadQueue(category: "Dýr")
    }

    // MARK: - Queue

    func loadQueue(category: String) {
        selectedCategory = category
        wordQueue = (store.words[category] ?? []).shuffled()
        guard !wordQueue.isEmpty else { return }
        queueIndex = 0
        loadWord(wordQueue[0])
    }

    func nextWord() {
        guard !wordQueue.isEmpty else { return }
        queueIndex = (queueIndex + 1) % wordQueue.count
        loadWord(wordQueue[queueIndex])
        impactLight.impactOccurred()
    }

    func prevWord() {
        guard !wordQueue.isEmpty else { return }
        queueIndex = (queueIndex - 1 + wordQueue.count) % wordQueue.count
        loadWord(wordQueue[queueIndex])
        impactLight.impactOccurred()
    }

    private func loadWord(_ entry: WordEntry) {
        currentWord = entry
        currentTiles = entry.allForms.map(\.word).shuffled()
        dropped = ["nef": nil, "thol": nil, "thag": nil, "eig": nil]
        zoneResult = [:]
        mistakeCount = 0
        correctCount = 0
    }

    // MARK: - Drop Handling

    func drop(word: String, intoKey key: String) {
        if zoneResult[key] == .correct { return }
        impactLight.impactOccurred()
        dropped[key] = word

        if currentWord.isCorrect(word, forKey: key) {
            zoneResult[key] = .correct
            notify.notificationOccurred(.success)
            correctCount += 1
            let award = min(correctCount, 5)
            coins += award
            coinBurst = award
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.coinBurst = 0
            }
            if correctCount == 4 { onWordComplete() }
        } else {
            zoneResult[key] = .wrong
            notify.notificationOccurred(.error)
            mistakeCount = min(mistakeCount + 1, maxMistakes)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                self.dropped[key] = nil
                self.zoneResult.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Completion

    private func onWordComplete() {
        impactMed.impactOccurred(intensity: 1.0)
        if isDaily {
            dailyWordsCompleted += 1
            if dailyWordsCompleted >= dailyWordTarget { onDailyComplete() }
        }
    }

    private func onDailyComplete() {
        updateStreak()
        notify.notificationOccurred(.success)
    }

    // MARK: - Streak

    private func refreshStreak() {
        guard lastPlayedEpoch > 0 else { return }
        let last = Date(timeIntervalSince1970: lastPlayedEpoch)
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 999
        if days > 1 { streak = 0 }
    }

    private func updateStreak() {
        let last = lastPlayedEpoch > 0 ? Date(timeIntervalSince1970: lastPlayedEpoch) : nil
        if let last, Calendar.current.isDateInToday(last) { return }
        streak += 1
        lastPlayedEpoch = Date().timeIntervalSince1970
    }

    var isGameOver: Bool { mistakeCount >= maxMistakes }

    func restartWord() {
        dropped = ["nef": nil, "thol": nil, "thag": nil, "eig": nil]
        zoneResult = [:]
        mistakeCount = 0
        correctCount = 0
        impactMed.impactOccurred()
    }

    func multiChoiceWrong() {
        mistakeCount = min(mistakeCount + 1, maxMistakes)
        notify.notificationOccurred(.error)
    }

    func awardCoins(_ n: Int) {
        coins += n
        coinBurst = n
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.coinBurst = 0 }
    }

    func hapticTap()  { impactMed.impactOccurred() }
    func hapticDrag() { impactLight.impactOccurred() }
}
