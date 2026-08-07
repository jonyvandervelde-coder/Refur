import SwiftUI
import Lottie

// MARK: - Emotional Fox Animation View

struct FoxView: View {
    @ObservedObject var session: SessionEngine
    @ObservedObject var game: GameState

    var foxEmotion: String {
        // Determine fox emotion based on game state
        switch session.phase {
        case .idle:
            return "Foxy_idle"
        case .playing:
            // Nervous when time is running out
            if session.timeRemaining <= 5 && session.timeRemaining > 0 {
                return "Foxy_nervous"
            }
            return "Foxy_confident"
        case .wordFailed:
            return "Foxy_sad"
        case .sessionComplete:
            return "Foxy_triumphant"
        case .sessionFailed:
            return "Foxy_sad"
        }
    }

    var body: some View {
        LottieView(name: foxEmotion, loopMode: .loop, playbackSpeed: 1.0)
            .frame(width: 180, height: 180)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Lottie Animation Wrapper

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let playbackSpeed: CGFloat

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        // Load from Lottie folder in the app bundle
        let animationView: LottieAnimationView
        if let bundlePath = Bundle.main.path(forResource: "Lottie", ofType: ""),
           let bundle = Bundle(path: bundlePath) {
            animationView = LottieAnimationView(name: name, bundle: bundle)
        } else {
            animationView = LottieAnimationView(name: name, bundle: .main)
        }

        animationView.loopMode = loopMode
        animationView.animationSpeed = playbackSpeed
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        context.coordinator.animationView = animationView
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }

        // Only update if animation name changed
        if animationView.animationName != name {
            animationView.animation = LottieAnimation.named(name)
            animationView.animationSpeed = playbackSpeed
            animationView.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var animationView: LottieAnimationView?
    }
}

// MARK: - Preview

#if DEBUG
struct FoxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.94, green: 0.98, blue: 1.00),
                Color(red: 0.88, green: 0.95, blue: 0.99)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 20) {
                FoxView(
                    session: SessionEngine(),
                    game: GameState()
                )
            }
        }
    }
}
#endif
