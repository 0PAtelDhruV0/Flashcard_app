# Deckflow — native SwiftUI app for iPhone and iPad

This is a **native iOS/iPadOS SwiftUI project** based on the design patterns visible in the supplied screen recording: dark gradient, native onboarding, subject chips, a featured library, deck previews, tab navigation, a simple study reader, and settings. This is not an HTML WebView.

## Open on iPad (no Mac required)

1. Install **Swift Playgrounds** from Apple's App Store on the iPad.
2. Download **Deckflow.swiftpm** as a folder, or download and extract the zip of this project, from the repository.
3. In Files, tap the **Deckflow.swiftpm** app playground or use Swift Playgrounds to open it.
4. Tap **Run**. You can test it on the iPad; App Store distribution requires Apple's signing and publication process.

For Xcode on a Mac, open `Deckflow.swiftpm` with a compatible version of Xcode and configure your own developer signing team and bundle ID as necessary.

The existing GitHub Pages web app at `https://0pateldhruv0.github.io/Flashcard_app/` remains a separate HTML website. GitHub Pages cannot compile or host native SwiftUI apps.

## What works

- **100% Apple native UI:** SwiftUI `TabView`, `NavigationStack`, `sheet`, `Form`, menus, SF Symbols, `FileImporter`, drag gestures.
- **GitHub-only public deck catalog:** auto-discovers `.csv` files in `0PAtelDhruV0/Flashcard_app` (`main` branch). Rename the repo or branch in Settings.
- **Every subject:** French, Spanish, mathematics, Sanskrit/Gita, and any new CSV category; user decks are local and separate from public GitHub decks.
- **Native text-to-speech:** `AVSpeechSynthesizer` selects Spanish, French, Hindi and other languages based on CSV `audio_lang` or deck language. Installed system voices and pronunciations vary.
- **Translation directly under the word:** a small, muted inline text with an optional eye control.
- **Real resume:** saves the last deck, exact card, translation visibility, filters, shuffle order, and learned status using Apple's `UserDefaults`.
- **Offline repeat study:** successfully downloaded decks are cached locally after first use. Network access is still needed to discover new GitHub decks.
- **Local custom decks:** import a CSV from Apple Files, or create a basic personal deck.
- **Study options:** level/type filters, shuffle, swipe navigation, favorites, and marks for learned cards.
- **Daily reminders:** optionally schedules a local 7 p.m. reminder through Apple `UserNotifications` (requires consent).

## CSV requirements

At least `front,back`, `french,meaning`, or `question,answer` headers are required. Optional columns: `example`, `example_translation`, `note`, `level`, `type`, `audio_lang`.

```
front,back,example,example_translation,note,level,type,audio_lang
Hola,Hello,"Hola, ¿cómo estás?","Hello, how are you?",Greeting,A1,Greetings,es-ES
```

New decks added under `decks/Languages/Spanish/...csv`, `decks/Mathematics/...`, etc. appear after Sync.

## Project structure

```
Deckflow.swiftpm/
  Package.swift
  AppModule/
    DeckflowApp.swift
    Models.swift
    CSVDeckService.swift
    DeckflowStore.swift
    DeckPalette.swift
    OnboardingView.swift
    LibraryView.swift
    HomeView.swift
    StudyView.swift
    SettingsView.swift
    CreateDeckSheet.swift
```

## Runtime limitations

- Not compiled against Apple's iOS SDK in this build environment. Run using Swift Playgrounds on iPad or Xcode on a Mac before shipping.
- GitHub's public API and raw content delivery require internet access and may enforce rate limits.
- Learning progress is stored **per device**, not synced to an Apple ID or iCloud account.
- Native speech may not give accurate classical Sanskrit pronunciation with the Hindi fallback voice.
- The recording includes premium sales and account signup screens. Those are intentionally not copied; Deckflow stays free and works without an account.
- App icon uses a system placeholder until branded artwork is provided.

## SwiftUI and Apple's frameworks

SwiftUI, Foundation, UniformTypeIdentifiers, AVFoundation, UserNotifications; no third-party packages or paid services.

## Verification

On a Mac with Xcode installed, open `Deckflow.swiftpm` and build for an iPhone/iPad simulator. The source is designed for iOS 17 and later.

On macOS/Linux with Swift 5.9+: run `sh Tests/run_core_tests.sh`. This validates CSV parsing, quotation and Unicode, folder classification, JSON identity roundtrip, and Swift file syntax. It **does not** compile the SwiftUI code against Apple's iOS SDK or verify its visual appearance.

The Swift package is deliberately kept in `native/` in the GitHub repository so it doesn't overwrite the working web app or its CSV decks.