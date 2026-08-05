import SwiftUI
import WebKit
import UIKit

/// WKWebView subclass that forwards the real native safe-area insets into
/// the page as CSS custom properties (`--safe-top` / `--safe-bottom`).
///
/// CSS `env(safe-area-inset-*)` reports 0 in this app's setup (custom
/// `app://` scheme + `.ignoresSafeArea()` on the SwiftUI host), so the web
/// content has no other way to know it's being drawn under the status bar
/// / Dynamic Island. Reading `safeAreaInsets` directly off the UIKit view
/// and pushing it in via JS sidesteps that and is accurate regardless of
/// device (notch, Dynamic Island, home indicator).
final class SafeAreaAwareWebView: WKWebView, WKNavigationDelegate {
    /// Fired every time the page finishes loading -- used to re-push
    /// native state (auth/native-language) into the fresh document.
    var onDidFinishLoad: (() -> Void)?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        navigationDelegate = self
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        injectSafeAreaVars()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        injectSafeAreaVars()
        onDidFinishLoad?()
    }

    /// Under memory pressure WebKit can kill the web content process
    /// without killing the app -- left alone, that's a permanently blank
    /// screen with no way back short of force-quitting. Reloading is the
    /// standard recovery: it re-runs index.html from scratch (all game
    /// state lives in localStorage, which survives this, so nothing is
    /// lost beyond the current in-memory screen).
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    private func injectSafeAreaVars() {
        let top = safeAreaInsets.top
        let bottom = safeAreaInsets.bottom
        // Also re-run reportTopbarLayout() (index.html) here: it may have
        // already fired once with --safe-top still at its pre-native
        // fallback value (0), which would measure the topbar's row a full
        // safe-area-inset too high. Re-measuring after the real inset
        // lands keeps the bridged profile-button position correct
        // regardless of that race, and on later calls (e.g. rotation)
        // this is just a harmless re-measurement of an unchanged layout.
        let js = "document.documentElement.style.setProperty('--safe-top','\(top)px');" +
                  "document.documentElement.style.setProperty('--safe-bottom','\(bottom)px');" +
                  "if(window.reportTopbarLayout) requestAnimationFrame(window.reportTopbarLayout);"
        evaluateJavaScript(js, completionHandler: nil)
    }
}

/// Thin SwiftUI wrapper around a WKWebView that loads the bundled Refur
/// web app. All game logic (drag-and-drop, daily puzzle, streaks,
/// feathers, the journey map) lives unmodified in www/index.html -- this
/// file's only job is hosting it natively.
struct WebView: UIViewRepresentable {
    let authManager: AuthManager

    func makeCoordinator() -> Coordinator {
        Coordinator(authManager: authManager)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: LocalSchemeHandler.scheme)
        config.userContentController.add(context.coordinator, name: "refurNative")

        let webView = SafeAreaAwareWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 251/255, green: 244/255, blue: 234/255, alpha: 1) // matches --refur-cream
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // Belt-and-suspenders zoom lock: the viewport meta tag
        // (maximum-scale=1, user-scalable=no) is what should stop pinch/
        // double-tap zoom, but WebKit has historically ignored that meta
        // tag in some iOS versions for accessibility reasons. Pinning the
        // scroll view's own zoom scale and disabling its pinch recognizer
        // makes the lock hold regardless of what WebKit does with the meta
        // tag.
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.bouncesZoom = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.onDidFinishLoad = { [weak authManager] in
            Task { @MainActor in
                authManager?.pushAuthStateToWeb()
            }
        }

        authManager.webView = webView

        if let url = URL(string: "\(LocalSchemeHandler.scheme)://\(LocalSchemeHandler.host)/index.html") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Nothing to sync -- the web app owns all of its own state.
    }

    /// Receives `window.webkit.messageHandlers.refurNative.postMessage(...)`
    /// calls from the page (see index.html's firstWordCompleted /
    /// motivationMilestoneReached / answerCorrect / answerWrong hooks) and
    /// forwards them to AuthManager or, for answers, straight to a haptic
    /// -- WKWebView has no Vibration API on iOS, so this bridge is the
    /// only way the drag-and-drop puzzle can give tactile feedback.
    final class Coordinator: NSObject, WKScriptMessageHandler {
        let authManager: AuthManager
        private let feedback = UINotificationFeedbackGenerator()
        private let heartbeat = UIImpactFeedbackGenerator(style: .medium)

        private var lightningTimer: Timer?
        private var lightningEndDate: Date?
        private var lastHeartbeatFire: Date = .distantPast
        private static let lightningSeconds: Double = 20

        init(authManager: AuthManager) {
            self.authManager = authManager
            super.init()
            feedback.prepare()
            // A backgrounded app stops firing Timers entirely, so without
            // this a countdown just silently pauses instead of expiring --
            // effectively letting someone "stop the clock" by backgrounding
            // mid-round. Recomputing from a fixed end date (rather than a
            // per-tick decrementing counter) the moment the app comes back
            // means the very next tick is correct regardless of how long it
            // was backgrounded, no separate catch-up logic required.
            NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func handleWillEnterForeground() {
            Task { @MainActor in
                self.tickLightning()
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let event = body["event"] as? String else { return }
            Task { @MainActor in
                switch event {
                case "firstWordCompleted":
                    authManager.handleFirstWordCompleted()
                case "motivationMilestoneReached":
                    authManager.handleMotivationMilestone()
                case "answerCorrect":
                    feedback.notificationOccurred(.success)
                    feedback.prepare()
                case "answerWrong":
                    feedback.notificationOccurred(.error)
                    feedback.prepare()
                case "startLightningMode":
                    startLightningTimer()
                case "lightningWon", "lightningLost":
                    stopLightningTimer()
                case "dailyPuzzleCompleted":
                    if let puzzleDate = body["puzzleDate"] as? String,
                       let correctCount = body["correctCount"] as? Int,
                       let mistakeCount = body["mistakeCount"] as? Int {
                        authManager.handleDailyPuzzleCompleted(puzzleDate: puzzleDate, correctCount: correctCount, mistakeCount: mistakeCount)
                    }
                case "openAefing":
                    authManager.showAefing = true
                case "requestSignIn":
                    authManager.requestSignIn()
                case "requestNativeLanguage":
                    authManager.requestNativeLanguagePrompt()
                case "topbarLayout":
                    if let top = body["top"] as? Double, let trailing = body["trailing"] as? Double {
                        authManager.profileButtonTop = top
                        authManager.profileButtonTrailing = trailing
                    }
                default:
                    break
                }
            }
        }

        /// Owns the Lightning Mode countdown natively rather than trusting a
        /// JS `setInterval` -- a backgrounded-adjacent webview can throttle
        /// JS timers, which would desync the haptic "heartbeat" from the
        /// visible bar. Native ticks at a fixed cadence and pushes the
        /// remaining time into the page via the same evaluateJavaScript
        /// pattern already used for safe-area/auth state.
        @MainActor private func startLightningTimer() {
            stopLightningTimer()
            lightningEndDate = Date().addingTimeInterval(Self.lightningSeconds)
            lastHeartbeatFire = .distantPast
            heartbeat.prepare()
            lightningTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                Task { @MainActor in self.tickLightning() }
            }
        }

        @MainActor private func stopLightningTimer() {
            lightningTimer?.invalidate()
            lightningTimer = nil
            lightningEndDate = nil
        }

        /// Recomputes remaining time from the fixed end date rather than
        /// decrementing a counter -- always wall-clock accurate, whether
        /// called from the regular 0.1s tick or right after returning from
        /// background.
        @MainActor private func tickLightning() {
            guard let endDate = lightningEndDate else { return }
            let remaining = endDate.timeIntervalSinceNow
            if remaining <= 0 {
                lightningTimer?.invalidate()
                lightningTimer = nil
                lightningEndDate = nil
                authManager.webView?.evaluateJavaScript("window.__lightningTimedOut && window.__lightningTimedOut();")
                return
            }
            authManager.webView?.evaluateJavaScript("window.__lightningTick && window.__lightningTick(\(remaining));")
            maybeFireHeartbeat(remaining: remaining)
        }

        /// Escalating "heartbeat" as time runs low: roughly 1/sec at 5-3s
        /// left, 2/sec at 3-1s, 4/sec in the final second -- distinct from
        /// a flat buzz, and separate from the answerCorrect/Wrong feedback.
        private func maybeFireHeartbeat(remaining: Double) {
            let interval: TimeInterval
            switch remaining {
            case ..<1: interval = 0.25
            case ..<3: interval = 0.5
            case ..<5: interval = 1.0
            default: return
            }
            guard Date().timeIntervalSince(lastHeartbeatFire) >= interval else { return }
            heartbeat.impactOccurred()
            lastHeartbeatFire = Date()
        }
    }
}
