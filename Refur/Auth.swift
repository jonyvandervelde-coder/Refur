import Foundation
import AuthenticationServices
import CryptoKit
import WebKit

/// Minimal Keychain wrapper so Supabase tokens never sit in UserDefaults in
/// plaintext. Only what this app needs: save/read/delete a string per key.
enum KeychainHelper {
    private static let service = "is.refur.app.auth"

    static func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Thin URLSession wrapper around the two Supabase HTTP surfaces this app
/// needs (Auth's native Apple id_token exchange, and PostgREST for the
/// `profiles` table). Chosen over the supabase-swift SPM package to avoid
/// adding a dependency graph to a project that currently has none -- this
/// covers the two calls we actually need.
enum SupabaseClient {
    static let projectURL = URL(string: "https://wlgbgsngxwvhlrozxtli.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndsZ2Jnc25neHd2aGxyb3p4dGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyMjYyNjYsImV4cCI6MjEwMDgwMjI2Nn0.-Pybu7eAY1fAaxinHGHr6SdTGzcyrQ4NboJsonQQrBI"

    struct Session {
        let accessToken: String
        let refreshToken: String
        let userId: String
        let expiresIn: Int
    }

    enum ClientError: Error { case badResponse, notSignedIn }

    /// Exchanges an Apple identity token for a Supabase session. `rawNonce`
    /// must be the *unhashed* nonce (Supabase hashes it itself to compare
    /// against the token's embedded nonce claim, which Apple set from the
    /// SHA256 we sent them).
    static func signInWithIdToken(idToken: String, rawNonce: String) async throws -> Session {
        var request = URLRequest(url: projectURL.appendingPathComponent("/auth/v1/token").appending(queryItems: [URLQueryItem(name: "grant_type", value: "id_token")]))
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "provider": "apple",
            "id_token": idToken,
            "nonce": rawNonce
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw ClientError.badResponse
        }
        let expiresIn = json["expires_in"] as? Int ?? 3600
        return Session(accessToken: accessToken, refreshToken: refreshToken, userId: userId, expiresIn: expiresIn)
    }

    /// Exchanges a still-valid refresh token for a new access token. Supabase
    /// rotates the refresh token on every use, so the caller must persist
    /// the *new* one returned here -- reusing the old one will fail next time.
    static func refreshSession(refreshToken: String) async throws -> Session {
        var request = URLRequest(url: projectURL.appendingPathComponent("/auth/v1/token").appending(queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")]))
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw ClientError.badResponse
        }
        let expiresIn = json["expires_in"] as? Int ?? 3600
        return Session(accessToken: accessToken, refreshToken: newRefreshToken, userId: userId, expiresIn: expiresIn)
    }

    /// Upserts the caller's own `profiles` row. Any nil field is omitted
    /// from the payload so it doesn't overwrite an existing value.
    static func upsertProfile(accessToken: String, userId: String, ageBracket: String?, nativeLanguage: String?, learningMotivation: [String]?) async throws {
        var body: [String: Any] = ["id": userId]
        if let ageBracket { body["age_bracket"] = ageBracket }
        if let nativeLanguage { body["native_language"] = nativeLanguage }
        if let learningMotivation { body["learning_motivation"] = learningMotivation }
        body["last_seen_at"] = ISO8601DateFormatter().string(from: Date())

        var request = URLRequest(url: projectURL.appendingPathComponent("/rest/v1/profiles"))
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse
        }
    }

    /// Records one day's outcome for the leaderboard/ticker features.
    /// Upserts on the (user_id, puzzle_date) unique constraint so a
    /// duplicate call (e.g. a retry) doesn't create a second row.
    static func insertDailyResult(accessToken: String, userId: String, puzzleDate: String, correctCount: Int, mistakeCount: Int) async throws {
        let body: [String: Any] = [
            "user_id": userId,
            "puzzle_date": puzzleDate,
            "correct_count": correctCount,
            "mistake_count": mistakeCount
        ]
        var request = URLRequest(url: projectURL.appendingPathComponent("/rest/v1/daily_results"))
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse
        }
    }

    /// Soft-delete: marks `deleted_at`. A scheduled server-side purge job
    /// (per the Privacy Policy's 30-day figure) is intentionally not part
    /// of this client-side change.
    static func softDeleteProfile(accessToken: String, userId: String) async throws {
        var request = URLRequest(url: projectURL.appendingPathComponent("/rest/v1/profiles").appending(queryItems: [URLQueryItem(name: "id", value: "eq.\(userId)")]))
        request.httpMethod = "PATCH"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["deleted_at": ISO8601DateFormatter().string(from: Date())])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse
        }
    }
}

/// Nonce helpers for the Sign in with Apple request. SwiftUI's own
/// `SignInWithAppleButton` handles the ASAuthorizationController
/// delegate/presentation-anchor plumbing, so this app doesn't need a
/// custom coordinator class for that part.
enum AppleNonce {
    static func randomString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Single source of truth for sign-in state and the progressive-onboarding
/// flags. Owned by ContentView as a @StateObject.
@MainActor
final class AuthManager: ObservableObject {
    @Published var signedIn: Bool = false
    @Published var ageBracket: String?
    @Published var nativeLanguage: String?
    @Published var learningMotivation: [String]?

    @Published var pendingNativeLanguagePrompt = false
    @Published var pendingMotivationPrompt = false
    @Published var pendingSignInPrompt = false

    /// Where ProfileButton should sit, as ready-to-use `.padding()` values
    /// (top / trailing, in points) -- measured by the web content itself
    /// from the topbar's real rendered layout and bridged over via
    /// WebView.swift's `topbarLayout` event, rather than guessed as fixed
    /// SwiftUI constants that would drift out of sync with it.
    @Published var profileButtonTop: CGFloat?
    @Published var profileButtonTrailing: CGFloat?
    @Published var showAefing = false

    private var userId: String?
    /// Set once by WebView after creating its WKWebView, so state changes
    /// here can push `window.__refurAuth` updates into the page.
    weak var webView: WKWebView?

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let accessToken = "refur.accessToken"
        static let refreshToken = "refur.refreshToken"
        static let accessTokenExpiresAt = "refur.accessTokenExpiresAt"
        static let userId = "refur.userId"
        static let nativeLanguage = "refur.nativeLanguage.local"
        static let shownNativeLanguagePrompt = "refur.shownNativeLanguagePrompt"
        static let shownMotivationPrompt = "refur.shownMotivationPrompt"
    }

    init() {
        nativeLanguage = defaults.string(forKey: Keys.nativeLanguage)
        if let uid = KeychainHelper.read(forKey: Keys.userId), KeychainHelper.read(forKey: Keys.accessToken) != nil {
            userId = uid
            signedIn = true
        }
    }

    // MARK: - Age-gated onboarding prompts (called from the WebView bridge)

    func handleFirstWordCompleted() {
        guard !defaults.bool(forKey: Keys.shownNativeLanguagePrompt) else { return }
        pendingNativeLanguagePrompt = true
    }

    func handleMotivationMilestone() {
        guard signedIn, !defaults.bool(forKey: Keys.shownMotivationPrompt) else { return }
        pendingMotivationPrompt = true
    }

    /// Explicit, user-initiated requests (e.g. "join a faction" on the
    /// Factions screen) -- unlike the automatic prompts above, these show
    /// every time they're tapped, regardless of the "already shown" flags.
    func requestSignIn() {
        pendingSignInPrompt = true
    }

    func requestNativeLanguagePrompt() {
        pendingNativeLanguagePrompt = true
    }

    func dismissNativeLanguagePrompt() {
        defaults.set(true, forKey: Keys.shownNativeLanguagePrompt)
        pendingNativeLanguagePrompt = false
    }

    func dismissMotivationPrompt() {
        defaults.set(true, forKey: Keys.shownMotivationPrompt)
        pendingMotivationPrompt = false
    }

    /// Pushes current sign-in/native-language state into the page. The web
    /// app doesn't consume this yet (no translated-hints feature exists),
    /// but it's wired now so that feature can read it later.
    func pushAuthStateToWeb() {
        guard let webView else { return }
        let langJSON = nativeLanguage.map { "\"\($0)\"" } ?? "null"
        let js = "window.__refurAuth = {signedIn: \(signedIn), nativeLanguage: \(langJSON)};"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func persist(_ session: SupabaseClient.Session) {
        KeychainHelper.save(session.accessToken, forKey: Keys.accessToken)
        KeychainHelper.save(session.refreshToken, forKey: Keys.refreshToken)
        defaults.set(Date().timeIntervalSince1970 + Double(session.expiresIn), forKey: Keys.accessTokenExpiresAt)
    }

    /// Returns an access token good for an actual network call, refreshing
    /// first if the stored one is at or near expiry. Supabase access tokens
    /// are short-lived (~1hr) -- without this, every write past that window
    /// would silently fail (the callers below all use `try?`) while the app
    /// still shows the user as signed in, since nothing else here ever
    /// re-derives a fresh token from the refresh token we already store.
    private func validAccessToken() async -> String? {
        guard let token = KeychainHelper.read(forKey: Keys.accessToken) else { return nil }
        let expiresAt = defaults.double(forKey: Keys.accessTokenExpiresAt)
        if expiresAt > 0 && Date().timeIntervalSince1970 < expiresAt - 60 {
            return token
        }
        guard let refreshToken = KeychainHelper.read(forKey: Keys.refreshToken) else { return token }
        guard let session = try? await SupabaseClient.refreshSession(refreshToken: refreshToken) else {
            return token // offline or refresh failed -- fall back to the stale token rather than blocking the caller
        }
        persist(session)
        return session.accessToken
    }

    // MARK: - Sign in / out / delete

    /// Completes sign-in from the result SwiftUI's `SignInWithAppleButton`
    /// hands back. `rawNonce` is the same unhashed value that was SHA256'd
    /// into the request's `nonce` field in `onRequest`.
    func completeSignIn(authorization: ASAuthorization, rawNonce: String, ageBracket: String) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            throw SupabaseClient.ClientError.badResponse
        }

        let session = try await SupabaseClient.signInWithIdToken(idToken: identityToken, rawNonce: rawNonce)

        try await SupabaseClient.upsertProfile(
            accessToken: session.accessToken,
            userId: session.userId,
            ageBracket: ageBracket,
            nativeLanguage: nativeLanguage,
            learningMotivation: nil
        )

        persist(session)
        KeychainHelper.save(session.userId, forKey: Keys.userId)

        self.userId = session.userId
        self.ageBracket = ageBracket
        self.signedIn = true
        pushAuthStateToWeb()
    }

    func signOut() {
        KeychainHelper.delete(forKey: Keys.accessToken)
        KeychainHelper.delete(forKey: Keys.refreshToken)
        KeychainHelper.delete(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.accessTokenExpiresAt)
        userId = nil
        signedIn = false
        ageBracket = nil
        learningMotivation = nil
        pushAuthStateToWeb()
    }

    func deleteMyData() async throws {
        guard let userId, let token = await validAccessToken() else {
            throw SupabaseClient.ClientError.notSignedIn
        }
        try await SupabaseClient.softDeleteProfile(accessToken: token, userId: userId)
        signOut()
    }

    func saveNativeLanguage(_ language: String) {
        nativeLanguage = language
        defaults.set(language, forKey: Keys.nativeLanguage)
        pushAuthStateToWeb()
        guard signedIn, let userId else { return }
        Task {
            guard let token = await validAccessToken() else { return }
            try? await SupabaseClient.upsertProfile(accessToken: token, userId: userId, ageBracket: nil, nativeLanguage: language, learningMotivation: nil)
        }
    }

    func saveMotivation(_ motivations: [String]) {
        guard signedIn, let userId else { return }
        learningMotivation = motivations
        Task {
            guard let token = await validAccessToken() else { return }
            try? await SupabaseClient.upsertProfile(accessToken: token, userId: userId, ageBracket: nil, nativeLanguage: nil, learningMotivation: motivations)
        }
    }

    /// Backs the Ambient Community feed and Language Factions leaderboard.
    /// A no-op for anonymous play -- both those features are inherently
    /// signed-in-only, since we only know a player's language once they've
    /// synced it, and this table only ever holds signed-in users' rows.
    func handleDailyPuzzleCompleted(puzzleDate: String, correctCount: Int, mistakeCount: Int) {
        guard signedIn, let userId else { return }
        Task {
            guard let token = await validAccessToken() else { return }
            try? await SupabaseClient.insertDailyResult(accessToken: token, userId: userId, puzzleDate: puzzleDate, correctCount: correctCount, mistakeCount: mistakeCount)
        }
    }
}
