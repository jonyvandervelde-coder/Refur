import SwiftUI
import AuthenticationServices

/// Colors ported 1:1 from index.html's `:root` / `prefers-color-scheme:
/// dark` CSS variables, so native chrome matches the web content in both
/// appearances the same way the game itself already does.
enum RefurColors {
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x2A241D)
    static let border = dynamic(light: 0xD9C7AC, dark: 0x463C31)
    static let text = dynamic(light: 0x221D18, dark: 0xF2EBE1)
    static let orangeDeep = dynamic(light: 0xB84711, dark: 0xD9691F)
    static let orangeInk = dynamic(light: 0x7A330E, dark: 0xFBD9C0)
    static let cream = dynamic(light: 0xFBF4EA, dark: 0x1B1713)
    static let wrongDeep = dynamic(light: 0x8F2C27, dark: 0xB4544E)
    static let wrong = dynamic(light: 0xC4453F, dark: 0xE67D77)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(refurHex: dark) : UIColor(refurHex: light)
        })
    }
}

private extension UIColor {
    convenience init(refurHex hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Reproduces the game's "3D press" button feel (CSS: a flat drop-shadow
/// at rest that collapses to nothing while `translateY`-ing the face down
/// on `:active`) for a circular button.
struct RefurCircleButtonStyle: ButtonStyle {
    var fill: Color
    var iconColor: Color
    var border: Color = RefurColors.border
    var shadow: Color = RefurColors.border
    var size: CGFloat = 38
    var shadowDepth: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle().fill(shadow).frame(width: size, height: size).offset(y: shadowDepth)
            Circle().fill(fill).frame(width: size, height: size)
                .overlay(Circle().stroke(border, lineWidth: 2.5))
                .overlay(configuration.label.foregroundStyle(iconColor))
                .offset(y: configuration.isPressed ? shadowDepth : 0)
        }
        .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

/// Same 3D-press language as `RefurCircleButtonStyle`, for the game's
/// pill/rounded-rect buttons (`.mapcta`, `.catbar button`, `.backbtn`).
struct RefurCapsuleButtonStyle: ButtonStyle {
    var fill: Color
    var textColor: Color
    var border: Color = RefurColors.border
    var shadow: Color = RefurColors.border
    var cornerRadius: CGFloat = 14
    var shadowDepth: CGFloat = 4
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.vertical, 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(
                ZStack {
                    shape.fill(shadow).offset(y: shadowDepth)
                    shape.fill(fill)
                    shape.stroke(border, lineWidth: 2)
                }
            )
            .offset(y: configuration.isPressed ? shadowDepth : 0)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

/// Small circular native affordance overlaid on top of the web view --
/// the "existing Sign in affordance" the login spec assumes is already
/// somewhere in Settings. Opens sign-in when signed out, account/delete
/// when signed in. Styled to match its row neighbor, the web content's
/// own Æfing pill: white/bordered at rest, filled orange like a completed
/// map day (`.map-node.done`) once signed in.
struct ProfileButton: View {
    @ObservedObject var authManager: AuthManager
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: authManager.signedIn ? "person.fill" : "person")
                .font(.system(size: 15, weight: .bold))
        }
        .buttonStyle(RefurCircleButtonStyle(
            fill: authManager.signedIn ? RefurColors.orangeDeep : RefurColors.surface,
            iconColor: authManager.signedIn ? RefurColors.cream : RefurColors.text,
            border: authManager.signedIn ? RefurColors.orangeDeep : RefurColors.border,
            shadow: authManager.signedIn ? RefurColors.orangeInk : RefurColors.border
        ))
        .sheet(isPresented: $showSheet) {
            if authManager.signedIn {
                AccountSheet(authManager: authManager)
            } else {
                SignInSheet(authManager: authManager)
            }
        }
    }
}

/// Age gate -> age bracket -> Sign in with Apple + terms, all one screen
/// per the onboarding spec's low-friction-mechanics rule.
struct SignInSheet: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    private enum Stage { case ageCheck, under13, ageBracket, appleSignIn }
    @State private var stage: Stage = .ageCheck
    @State private var ageBracket = "18_plus"
    @State private var agreedToTerms = false
    @State private var showTermsSheet = false
    @State private var rawNonce = AppleNonce.randomString()
    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch stage {
                case .ageCheck: ageCheckView
                case .under13: under13View
                case .ageBracket: ageBracketView
                case .appleSignIn: appleSignInView
                }
            }
            .padding()
            .navigationTitle("Skrá inn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Loka") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showTermsSheet) { TermsPrivacySheet() }
    }

    private var ageCheckView: some View {
        VStack(spacing: 16) {
            Text("Fljótleg spurning áður en þú skráir þig inn").font(.headline)
            Text("Ertu 13 ára eða eldri?")
            HStack(spacing: 12) {
                Button("Já, ég er 13+") { stage = .ageBracket }
                    .buttonStyle(RefurCapsuleButtonStyle(fill: RefurColors.orangeDeep, textColor: RefurColors.cream, border: RefurColors.orangeInk, shadow: RefurColors.orangeInk, fullWidth: false))
                Button("Ekki enn") { stage = .under13 }
                    .buttonStyle(RefurCapsuleButtonStyle(fill: RefurColors.surface, textColor: RefurColors.text, fullWidth: false))
            }
        }
    }

    private var under13View: some View {
        VStack(spacing: 16) {
            Text("Ekkert mál").font(.headline)
            Text("Refur þarf ekki aðgang fyrir neinn undir 13 ára aldri — allt sem þú hefur gert vistast nú þegar hér á tækinu þínu.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Loka") { dismiss() }
                .buttonStyle(RefurCapsuleButtonStyle(fill: RefurColors.orangeDeep, textColor: RefurColors.cream, border: RefurColors.orangeInk, shadow: RefurColors.orangeInk, fullWidth: false))
        }
    }

    private var ageBracketView: some View {
        VStack(spacing: 16) {
            Text("Aldursbil").font(.headline)
            Picker("Aldursbil", selection: $ageBracket) {
                Text("13–17 ára").tag("13_17")
                Text("18 ára og eldri").tag("18_plus")
            }
            .pickerStyle(.segmented)
            Button("Áfram") { stage = .appleSignIn }
                .buttonStyle(RefurCapsuleButtonStyle(fill: RefurColors.orangeDeep, textColor: RefurColors.cream, border: RefurColors.orangeInk, shadow: RefurColors.orangeInk, fullWidth: false))
        }
    }

    private var appleSignInView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    agreedToTerms.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        Text("Ég samþykki skilmálana og persónuverndarstefnuna")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)

                Button("Lesa skilmála og persónuverndarstefnu") { showTermsSheet = true }
                    .font(.caption)
                    .padding(.leading, 24)
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleNonce.sha256(rawNonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    isSigningIn = true
                    Task {
                        do {
                            try await authManager.completeSignIn(authorization: authorization, rawNonce: rawNonce, ageBracket: ageBracket)
                            isSigningIn = false
                            dismiss()
                        } catch {
                            isSigningIn = false
                            errorMessage = "Innskráning mistókst. Prófaðu aftur."
                        }
                    }
                case .failure:
                    errorMessage = "Innskráning mistókst. Prófaðu aftur."
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .disabled(!agreedToTerms || isSigningIn)
            .opacity(agreedToTerms ? 1 : 0.5)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.footnote)
            }
        }
    }
}

/// "Want hints in your own language?" -- contextual tier, shown once after
/// the first completed word, no account required.
struct NativeLanguageSheet: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var selected = "en"

    private static let languages: [(code: String, name: String)] = [
        ("en", "English"), ("pl", "Polski"), ("es", "Español"), ("de", "Deutsch"),
        ("fr", "Français"), ("it", "Italiano"), ("pt", "Português"), ("ru", "Русский"),
        ("uk", "Українська"), ("lt", "Lietuvių"), ("vi", "Tiếng Việt"), ("th", "ไทย"),
        ("ar", "العربية"), ("zh", "中文"), ("ja", "日本語"), ("ko", "한국어"), ("is", "Íslenska")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Viltu vísbendingar á þínu tungumáli?").font(.title3.bold())
            Text("Við getum sýnt þýðingar á móðurmálinu þínu í stað ensku.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Picker("Tungumál", selection: $selected) {
                ForEach(Self.languages, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            .pickerStyle(.wheel)
            Button("Vista") {
                authManager.saveNativeLanguage(selected)
                authManager.dismissNativeLanguagePrompt()
                dismiss()
            }
            .buttonStyle(RefurCapsuleButtonStyle(fill: RefurColors.orangeDeep, textColor: RefurColors.cream, border: RefurColors.orangeInk, shadow: RefurColors.orangeInk))
            Button("Sleppa í bili") {
                authManager.dismissNativeLanguagePrompt()
                dismiss()
            }
            .font(.footnote)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

/// "What's bringing you to Icelandic?" -- drip tier, signed-in users only.
struct MotivationSheet: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []

    private let options: [(key: String, label: String)] = [
        ("work", "Vinna"), ("family", "Fjölskylda"), ("academic", "Nám"), ("fun", "Bara gaman")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Hvað er að draga þig að íslensku?").font(.title3.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(options, id: \.key) { option in
                    Button {
                        if selected.contains(option.key) {
                            selected.remove(option.key)
                        } else {
                            selected.insert(option.key)
                        }
                    } label: {
                        Text(option.label)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selected.contains(option.key) ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundStyle(selected.contains(option.key) ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            Button("Vista") {
                authManager.saveMotivation(Array(selected))
                authManager.dismissMotivationPrompt()
                dismiss()
            }
            .buttonStyle(RefurCapsuleButtonStyle(fill: RefurColors.orangeDeep, textColor: RefurColors.cream, border: RefurColors.orangeInk, shadow: RefurColors.orangeInk))
            .disabled(selected.isEmpty)
            Button("Sleppa") {
                authManager.dismissMotivationPrompt()
                dismiss()
            }
            .font(.footnote)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

struct AccountSheet: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Reikningur") {
                    if let lang = authManager.nativeLanguage {
                        LabeledContent("Móðurmál", value: lang)
                    }
                    Button("Skrá út") {
                        authManager.signOut()
                        dismiss()
                    }
                }
                Section {
                    Button("Eyða gögnunum mínum", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Reikningur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Loka") { dismiss() }
                }
            }
            .confirmationDialog(
                "Eyða öllum gögnum sem tengjast reikningnum þínum?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Eyða", role: .destructive) {
                    Task {
                        do {
                            try await authManager.deleteMyData()
                            dismiss()
                        } catch {
                            errorMessage = "Eitthvað fór úrskeiðis. Prófaðu aftur."
                        }
                    }
                }
                Button("Hætta við", role: .cancel) {}
            }
        }
    }
}

struct TermsPrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Skilmálar").font(.title2.bold())
                    Text(RefurLegalText.terms).font(.footnote)
                    Divider()
                    Text("Persónuverndarstefna").font(.title2.bold())
                    Text(RefurLegalText.privacy).font(.footnote)
                }
                .padding()
            }
            .navigationTitle("Skilmálar og persónuvernd")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Loka") { dismiss() }
                }
            }
        }
    }
}

enum RefurLegalText {
    static let terms = """
    Refur is a free, non-commercial Icelandic-language learning game, provided by Jonathan (Johnny) Guedez as a personal, educational project. There are no purchases, no subscriptions, and no advertising inside Refur.

    Refur's core game (daily puzzle, practice mode, streaks) can be used without creating an account, at any age, entirely on your own device. Signing in via Sign in with Apple is optional and only needed if you want your progress to sync or want to help us understand who's learning Icelandic with Refur.

    If you are under 13, you can use the local, no-login version of Refur freely, but should not create a signed-in account without a parent or legal guardian's permission.

    Word inflection data is sourced in part from Beygingarlýsing íslensks nútímamáls (BÍN), maintained by Stofnun Árna Magnússonar í íslenskum fræðum, licensed under CC BY-SA 4.0:
    "Beygingarlýsing íslensks nútímamáls. Stofnun Árna Magnússonar í íslenskum fræðum. Höfundur og ritstjóri Kristín Bjarnadóttir."

    Please don't attempt to reverse-engineer, disrupt, or overload the app or any backend service behind it, or misrepresent your age to bypass the protections above.

    If you sign in, you're responsible for the Apple ID or device you use to do so. You can delete your account and all associated data at any time from within the app.

    Refur is provided "as is," without warranties of any kind, including as to accuracy of grammar content. It is not a substitute for a real Icelandic course or a native speaker's review.

    Since Refur is free and non-commercial, total liability for any claim arising from the app is limited to zero.

    These terms are governed by the laws of Iceland. Questions: jonyvandervelde@gmail.com.
    """

    static let privacy = """
    You can use Refur's entire core game — daily puzzle, practice, streaks — without ever signing in or sharing any personal data. Everything stays on your device.

    Signing in is optional, uses Sign in with Apple only, and is the only way any persisted data reaches us at all. We never sell data, never show ads, and never share your data with anyone except the infrastructure provider that stores it on our behalf.

    Data collected when you don't sign in: none is stored about you, beyond what's needed for the app to function on your device (streak, feathers, shield count, daily puzzle history — all local only). One narrow exception: to show the live "people playing now" count on the map, your device sends an anonymous, randomly-generated ID (not linked to your identity in any way) roughly every 30 seconds while the app is open. This ping is never written to permanent storage — it only exists for about 90 seconds to be counted, then it's gone. If you'd rather not send even that, you can turn off network access for Refur in iOS Settings and every other feature keeps working normally.

    Data collected when you sign in:
    • Apple's stable user identifier (and relay email, if provided) — to recognize you across sessions and sync progress.
    • Native language — to tailor hints/translations, and in aggregate to understand our learner base.
    • Rough age bracket (13-17 / 18+) — a legal consent gate, not profiling.
    • Anything else you choose to share (e.g. why you're learning Icelandic) — always optional, always skippable.

    We deliberately do not collect location, contacts, device advertising identifiers, or browsing history.

    Your data lives with our backend infrastructure provider, hosted in an EU region so it doesn't need to leave the EEA.

    We keep signed-in profile data for as long as your account exists, or delete it automatically after 24 months of inactivity. You can delete it yourself at any time (this Account screen → Delete my data), which removes your profile within 30 days.

    Children's privacy: Iceland's Data Protection Act sets the digital age of consent at 13. If you're under 13, Refur's sign-in step isn't available to you directly, but every core feature works fully in local/no-login mode with zero data collection, at any age.

    Under GDPR you have the right to access, correct, delete, export, object to, or restrict our processing of your data, and to withdraw consent at any time. Email jonyvandervelde@gmail.com — we'll respond within 30 days. You can also lodge a complaint with Iceland's data protection authority, Persónuvernd (www.personuvernd.is).

    The only third parties involved are Apple (for Sign in with Apple) and our backend/hosting provider, acting strictly as a data processor. We do not use analytics SDKs, ad networks, or tracking pixels.

    Contact: jonyvandervelde@gmail.com.
    """
}
