import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WebView(authManager: authManager)
                .ignoresSafeArea()

            // index.html measures its own topbar's real rendered layout
            // (the 46px gutter it reserves beside the brand mark / Æfing
            // pill) and bridges the exact padding this button needs via
            // the `topbarLayout` native event -- see reportTopbarLayout()
            // in index.html and WebView.swift's message handler. Fall back
            // to the pre-measurement estimate only for the first frame,
            // before that event has fired.
            // .ignoresSafeArea() here matters: the measured `top`/`trailing`
            // values from index.html are absolute screen coordinates (the
            // same coordinate space the edge-to-edge WebView measures
            // itself in). Without this, SwiftUI would silently add its own
            // safe-area top inset underneath our padding, double-counting
            // it on top of the already-safe-area-aware measurement.
            ProfileButton(authManager: authManager)
                .padding(.trailing, authManager.profileButtonTrailing ?? 10)
                .padding(.top, authManager.profileButtonTop ?? 4)
                .ignoresSafeArea()
        }
        .statusBarHidden(false)
        .fullScreenCover(isPresented: $authManager.showAefing) {
            AefingView()
        }
        .sheet(isPresented: $authManager.pendingNativeLanguagePrompt) {
            NativeLanguageSheet(authManager: authManager)
        }
        .sheet(isPresented: $authManager.pendingMotivationPrompt) {
            MotivationSheet(authManager: authManager)
        }
        .sheet(isPresented: $authManager.pendingSignInPrompt) {
            SignInSheet(authManager: authManager)
        }
    }
}
