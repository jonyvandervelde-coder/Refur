# Refur — Xcode project

This is Refur wrapped as a native iOS app. It's a thin SwiftUI + WKWebView
shell around the exact same index.html/words.json you've already been
testing as a web app — no game logic was rewritten, so everything (theme,
journey map, feathers, streak shield) behaves identically.

## Opening it

1. Unzip this, then double-click `Refur.xcodeproj` — it opens directly in Xcode, no setup wizard needed.
2. Click the "Refur" project in the navigator → the "Refur" target → the **Signing & Capabilities** tab.
3. Under **Team**, pick your own name/Apple ID (Xcode adds a free personal team automatically the first time you sign into Xcode with your Apple ID under Xcode → Settings → Accounts).
4. Xcode will complain about the bundle identifier `is.refur.app` possibly being taken — if so, just change it to something like `is.refur.<yourname>` in the same tab. It's a placeholder either way.

## Running it

- **Simulator**: pick any iPhone simulator from the device dropdown at the top and hit ▶️ (Cmd+R). Nothing else required.
- **Your own phone**: plug it in, select it from the device dropdown, hit ▶️. The first time, your phone will show an "Untrusted Developer" warning — go to Settings → General → VPN & Device Management on the phone and trust your Apple ID, then relaunch from Xcode. Free Apple ID signing is valid for 7 days at a time (you'll just need to rebuild from Xcode again after that), which is normal for personal/testing use without a paid Apple Developer account.

## What's actually in here

- `Refur/RefurApp.swift`, `ContentView.swift` — the SwiftUI app shell (two tiny files).
- `Refur/WebView.swift` + `LocalSchemeHandler.swift` — hosts the web app over a fixed custom URL scheme (`app://refur/...`) rather than a plain `file://` load. This is deliberate: it gives the web view a stable "origin" across app launches, so `localStorage` (which is where streaks, feathers, and shields live) persists reliably the same way it does on a real website. A plain file:// load can behave inconsistently here across iOS versions.
- `Refur/www/` — your existing web app, untouched: `index.html`, `words.json`, `manifest.json`, icons. This is the same content you've been testing via the browser link; edits you make to your web version can just be copied into this folder to update the native build.
- `Refur/Assets.xcassets/AppIcon` — the fox icon, upscaled to the 1024×1024 size Xcode wants for the app icon slot. Swap in real 1024×1024 artwork here later if you want higher fidelity than the upscale.

## Known limitation

`manifest.json` and `sw.js` (the PWA install-prompt / offline-cache files) are harmless leftovers from the web version — they don't do anything inside the native wrapper and can be deleted from `Refur/www/` if you want to tidy up, but leaving them in doesn't cause any problem.
