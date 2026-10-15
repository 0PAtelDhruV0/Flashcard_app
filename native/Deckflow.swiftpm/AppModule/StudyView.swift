import SwiftUI
import AVFoundation

@MainActor
final class DeckSpeechPlayer: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String, locale: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = 0.46
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}

struct StudyView: View {
    @EnvironmentObject private var store: DeckflowStore
    @StateObject private var player = DeckSpeechPlayer()
    @Environment(\.dismiss) private var dismiss
    @State private var dragDistance: CGFloat = 0
    @State private var filtersPresented = false

    private var card: Flashcard? { store.currentCard }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .center, spacing: 17) {
                        titleBlock
                        if let card {
                            mainCard(card)
                            if !card.example.isEmpty || !card.note.isEmpty { detailCard(card) }
                        } else {
                            ContentUnavailableView("No matching cards", systemImage: "rectangle.stack",
                                                   description: Text("Change the level or card type filter."))
                        }
                    }
                    .frame(maxWidth: min(750, geometry.size.width - 22))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
            .background(DeckPalette.screenGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { player.stop(); store.isStudying = false; dismiss() } label: {
                        HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Decks") }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(store.activeDeck?.title ?? "Study")
                        .font(.system(size: 14, weight: .semibold)).lineLimit(1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { filtersPresented = true } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                        .accessibilityLabel("Study filters")
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .sheet(isPresented: $filtersPresented) { filtersSheet }
            .onDisappear { player.stop(); store.saveSession() }
        }
        .preferredColorScheme(.dark)
    }

    private var titleBlock: some View {
        VStack(spacing: 13) {
            HStack {
                Text(store.activeDeck?.topic ?? "")
                    .font(.caption).foregroundStyle(DeckPalette.muted)
                Spacer()
                Text("\(store.visibleCards.isEmpty ? 0 : store.cardIndex + 1) / \(store.visibleCards.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(DeckPalette.muted)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(DeckPalette.elevated)
                    Capsule().fill(DeckPalette.cardGradient)
                        .frame(width: proxy.size.width * CGFloat(store.visibleCards.isEmpty ? 0 : Double(store.cardIndex + 1) / Double(store.visibleCards.count)))
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 17)
    }

    private func mainCard(_ current: Flashcard) -> some View {
        NativePanel {
            VStack(spacing: 16) {
                HStack {
                    Text("FLASHCARD")
                        .font(.system(size: 10, weight: .bold)).tracking(2)
                        .foregroundStyle(DeckPalette.muted)
                    Spacer()
                    if store.isLearned(current) {
                        Label("Learned", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                    }
                }
                Spacer(minLength: 12)
                Text(current.front)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.52)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if store.showTranslation {
                    Text(current.back)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DeckPalette.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, -7)
                }
                Spacer(minLength: 14)
                HStack(spacing: 9) {
                    smallAction(store.showTranslation ? "Hide meaning" : "Show meaning",
                                icon: store.showTranslation ? "eye.slash" : "eye") {
                        store.toggleTranslation()
                    }
                    smallAction("Listen", icon: "speaker.wave.2") {
                        player.speak(current.front, locale: speechLocale(for: current))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 270)
            .padding(18)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 55).onEnded { value in
                if value.translation.width < -75 { store.advance(1) }
                else if value.translation.width > 75 { store.advance(-1) }
            })
        }
        .padding(.horizontal, 5)
    }

    private func detailCard(_ current: Flashcard) -> some View {
        NativePanel {
            VStack(alignment: .leading, spacing: 13) {
                if !current.example.isEmpty {
                    HStack {
                        Text("EXAMPLE").font(.system(size: 10, weight: .bold)).tracking(1.5)
                            .foregroundStyle(DeckPalette.muted)
                        Spacer()
                        Button { player.speak(current.example, locale: speechLocale(for: current)) } label: {
                            Image(systemName: "speaker.wave.2")
                        }.accessibilityLabel("Speak example")
                    }
                    Text(current.example).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    if !current.exampleTranslation.isEmpty {
                        Text(current.exampleTranslation).font(.caption).foregroundStyle(DeckPalette.muted)
                    }
                }
                if !current.note.isEmpty {
                    if !current.example.isEmpty { Divider().overlay(DeckPalette.stroke) }
                    Text("NOTE").font(.system(size: 10, weight: .bold)).tracking(1.5)
                        .foregroundStyle(DeckPalette.muted)
                    Text(current.note).font(.system(size: 13)).foregroundStyle(DeckPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }.padding(.horizontal, 5)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                Button { store.advance(-1) } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline).frame(maxWidth: .infinity).frame(height: 48)
                        .background(DeckPalette.elevated, in: RoundedRectangle(cornerRadius: 12))
                }
                Button { store.toggleLearned() } label: {
                    Label(store.currentCard.map { store.isLearned($0) } == true ? "Learned" : "Mark learned",
                          systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(DeckPalette.elevated, in: RoundedRectangle(cornerRadius: 12))
                }
                Button { store.advance(1) } label: {
                    HStack { Text("Next"); Image(systemName: "arrow.right") }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(DeckPalette.cardGradient, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .buttonStyle(.plain)
            .disabled(store.visibleCards.isEmpty)
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    private var filtersSheet: some View {
        NavigationStack {
            Form {
                Picker("Level", selection: Binding(get: { store.levelFilter }, set: { store.setLevel($0) })) {
                    ForEach(store.availableLevels, id: \.self) { Text($0).tag($0) }
                }
                Picker("Card type", selection: Binding(get: { store.typeFilter }, set: { store.setType($0) })) {
                    ForEach(store.availableTypes, id: \.self) { Text($0).tag($0) }
                }
                Toggle("Shuffle cards", isOn: Binding(get: { store.shuffled }, set: { _ in store.toggleShuffle() }))
                Toggle("Show translation beneath word", isOn: Binding(get: { store.showTranslation }, set: { _ in store.toggleTranslation() }))
            }
            .navigationTitle("Study options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { filtersPresented = false } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func smallAction(_ label: String, icon: String, handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 13).frame(height: 38)
                .background(DeckPalette.elevated, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func speechLocale(for card: Flashcard) -> String {
        if !card.audioLanguage.isEmpty { return card.audioLanguage }
        switch (store.activeDeck?.language ?? store.activeDeck?.topic ?? "").lowercased() {
        case "spanish": "es-ES"
        case "french": "fr-FR"
        case "sanskrit", "hindi": "hi-IN"
        case "german": "de-DE"
        case "italian": "it-IT"
        case "japanese": "ja-JP"
        case "portuguese": "pt-PT"
        default: "en-US"
        }
    }
}