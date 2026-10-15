import Foundation
import SwiftUI

@MainActor
final class DeckflowStore: ObservableObject {
    @Published var catalog: [StudyDeck] = []
    @Published var localDecks: [StudyDeck] = []
    @Published var isSyncing = false
    @Published var message: String?
    @Published var previewDeck: StudyDeck?
    @Published var previewCards: [Flashcard] = []
    @Published var previewLoading = false
    @Published var activeDeck: StudyDeck?
    @Published var activeCards: [Flashcard] = []
    @Published var visibleCards: [Flashcard] = []
    @Published var cardIndex = 0
    @Published var isStudying = false
    @Published var showTranslation = true
    @Published var shuffled = false
    @Published var levelFilter = "All"
    @Published var typeFilter = "All"
    @Published var learned: [String: Set<String>] = [:]
    @Published var favoriteDeckIDs: Set<String> = []
    @Published var dailyGoal = 15
    @Published var preferredLanguage = "Spanish"
    @Published var hasOnboarded = false
    @Published var repository = "0PAtelDhruV0/Flashcard_app"
    @Published var branch = "main"
    @Published var completedToday = 0
    @Published var darkMode = true

    private var cache: [String: [Flashcard]] = [:]
    private var saved: SavedSession?
    private let defaults = UserDefaults.standard
    private let prefix = "deckflow.native.v1."
    private var initialized = false

    var allDecks: [StudyDeck] { localDecks + catalog }
    var subjects: [String] {
        Array(Set(allDecks.map(\.subject))).sorted { a, b in
            if a == "Languages" { return true }
            if b == "Languages" { return false }
            return a < b
        }
    }
    var currentCard: Flashcard? { visibleCards.indices.contains(cardIndex) ? visibleCards[cardIndex] : nil }
    var learnedCount: Int { learned.values.reduce(0) { $0 + $1.count } }
    var featuredDecks: [StudyDeck] {
        let starred = allDecks.filter { favoriteDeckIDs.contains($0.id) }
        let rest = allDecks.filter { !favoriteDeckIDs.contains($0.id) }
        return Array((starred + rest).prefix(8))
    }
    var availableLevels: [String] { ["All"] + Array(Set(activeCards.map(\.level).filter { !$0.isEmpty })).sorted() }
    var availableTypes: [String] { ["All"] + Array(Set(activeCards.map(\.type).filter { !$0.isEmpty })).sorted() }

    init() {
        if let arr: [StudyDeck] = get("catalog") { catalog = arr }
        if let arr: [StudyDeck] = get("localDecks") { localDecks = arr }
        if let stored: [String: [Flashcard]] = get("cardCache") { cache = stored }
        if let values: [String: [String]] = get("learned") {
            learned = values.mapValues { Set($0) }
        }
        if let favorite: [String] = get("favorites") { favoriteDeckIDs = Set(favorite) }
        if let old: SavedSession = get("session") { saved = old }
        if let value: Int = get("goal") { dailyGoal = value }
        if let value: Int = get("done") { completedToday = value }
        if let value: String = get("preferredLanguage") { preferredLanguage = value }
        if let value: Bool = get("onboarded") { hasOnboarded = value }
        if let value: Bool = get("dark") { darkMode = value }
        if let value: String = get("repo") { repository = value }
        if let value: String = get("branch") { branch = value }
    }

    private func get<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: prefix + key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    private func put<T: Encodable>(_ key: String, _ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: prefix + key)
    }

    func initialize() async {
        guard !initialized else { return }
        initialized = true
        // Restore the exact card before refreshing the network catalog.
        if let session = saved, let deck = allDecks.first(where: { $0.id == session.deckID }) {
            await beginStudy(deck, recovering: session)
        }
        await sync()
        // If the app never cached this deck, try again after GitHub discovery.
        if activeDeck == nil, let session = saved, let deck = allDecks.first(where: { $0.id == session.deckID }) {
            await beginStudy(deck, recovering: session)
        }
    }

    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let fresh = try await GitHubDeckService.discover(repository: repository, branch: branch)
            catalog = fresh
            put("catalog", catalog)
            message = nil
        } catch {
            message = "Can't sync GitHub: \(error.localizedDescription). Saved decks remain available."
        }
    }

    func preview(_ deck: StudyDeck) async {
        previewDeck = deck
        previewLoading = true
        previewCards = []
        do { previewCards = try await getCards(deck) }
        catch { message = error.localizedDescription }
        previewLoading = false
    }

    func beginStudy(_ deck: StudyDeck, recovering session: SavedSession? = nil) async {
        do {
            let cards = try await getCards(deck)
            activeDeck = deck
            activeCards = cards
            levelFilter = session?.levelFilter ?? "All"
            typeFilter = session?.typeFilter ?? "All"
            shuffled = session?.order.isEmpty == false
            showTranslation = session?.showTranslation ?? true
            applyFilters(restoring: session)
            previewDeck = nil
            isStudying = true
            saveSession()
        } catch { message = "Couldn't open \(deck.title): \(error.localizedDescription)" }
    }

    private func getCards(_ deck: StudyDeck) async throws -> [Flashcard] {
        if let embedded = deck.cards { return embedded }
        if let cached = cache[deck.id], !cached.isEmpty { return cached }
        let cards = try await GitHubDeckService.download(deck, repository: repository, branch: branch)
        cache[deck.id] = cards
        // Cache downloaded cards on device so resuming works without the network.
        put("cardCache", cache)
        return cards
    }

    func applyFilters(restoring session: SavedSession? = nil) {
        let filtered = activeCards.filter {
            (levelFilter == "All" || $0.level == levelFilter) && (typeFilter == "All" || $0.type == typeFilter)
        }
        if shuffled {
            if let session, !session.order.isEmpty {
                let indexes = Dictionary(uniqueKeysWithValues: session.order.enumerated().map { ($0.element, $0.offset) })
                visibleCards = filtered.sorted { indexes[$0.id, default: Int.max] < indexes[$1.id, default: Int.max] }
            } else { visibleCards = filtered.shuffled() }
        } else { visibleCards = filtered }
        if let session, let restored = visibleCards.firstIndex(where: { $0.id == session.cardID }) {
            cardIndex = restored
        } else { cardIndex = min(session?.index ?? 0, max(0, visibleCards.count - 1)) }
        saveSession()
    }

    func setLevel(_ value: String) { levelFilter = value; applyFilters() }
    func setType(_ value: String) { typeFilter = value; applyFilters() }
    func toggleShuffle() { shuffled.toggle(); applyFilters() }
    func toggleTranslation() { showTranslation.toggle(); saveSession() }
    func advance(_ amount: Int) {
        guard !visibleCards.isEmpty else { return }
        cardIndex = (cardIndex + amount + visibleCards.count) % visibleCards.count
        saveSession()
    }
    func setCard(_ index: Int) {
        guard visibleCards.indices.contains(index) else { return }
        cardIndex = index
        saveSession()
    }
    func toggleLearned() {
        guard let deck = activeDeck, let card = currentCard else { return }
        var values = learned[deck.id, default: []]
        if values.contains(card.id) { values.remove(card.id) }
        else { values.insert(card.id); completedToday += 1; put("done", completedToday) }
        learned[deck.id] = values
        put("learned", learned.mapValues { Array($0) })
        saveSession()
    }
    func toggleFavorite(_ deck: StudyDeck) {
        if favoriteDeckIDs.contains(deck.id) { favoriteDeckIDs.remove(deck.id) }
        else { favoriteDeckIDs.insert(deck.id) }
        put("favorites", Array(favoriteDeckIDs))
    }
    func isLearned(_ card: Flashcard) -> Bool { learned[activeDeck?.id ?? "", default: []].contains(card.id) }
    func learnedFor(_ deck: StudyDeck) -> Int { learned[deck.id]?.count ?? 0 }

    func saveSession() {
        guard let deck = activeDeck, let card = currentCard else { return }
        let session = SavedSession(deckID: deck.id, index: cardIndex, cardID: card.id,
                                   showTranslation: showTranslation, levelFilter: levelFilter,
                                   typeFilter: typeFilter, order: shuffled ? visibleCards.map(\.id) : [])
        saved = session
        put("session", session)
    }

    func setGoal(_ minutes: Int) { dailyGoal = minutes; put("goal", minutes) }
    func setLanguage(_ language: String) { preferredLanguage = language; put("preferredLanguage", language) }
    func completeOnboarding() { hasOnboarded = true; put("onboarded", true) }
    func setDark(_ dark: Bool) { darkMode = dark; put("dark", dark) }
    func setRepository(_ name: String, branch newBranch: String) {
        guard GitHubDeckService.validRepository(name), !newBranch.clean.isEmpty else {
            message = "Enter a public GitHub repo in owner/name format."
            return
        }
        repository = name.clean; branch = newBranch.clean
        put("repo", repository); put("branch", branch)
        catalog = []; cache = [:]; put("catalog", catalog); put("cardCache", cache)
        activeDeck = nil; isStudying = false; saved = nil
        defaults.removeObject(forKey: prefix + "session")
    }

    func importCSV(from url: URL) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else { throw DeckflowError.invalidDocument }
        let cards = try CSVDeckParser.parse(text)
        let title = url.deletingPathExtension().lastPathComponent.prettyDeckName
        let deck = StudyDeck(id: "local:\(UUID().uuidString)", title: title, subject: "My Decks",
                             topic: "Imported", origin: .local, cards: cards)
        localDecks.insert(deck, at: 0)
        put("localDecks", localDecks)
    }

    func createDeck(title: String, subject: String, front: String, back: String) {
        guard !title.clean.isEmpty, !front.clean.isEmpty, !back.clean.isEmpty else { return }
        let card = Flashcard(front: front.clean, back: back.clean)
        let deck = StudyDeck(id: "local:\(UUID().uuidString)", title: title.clean,
                             subject: subject.clean.isEmpty ? "My Decks" : subject.clean,
                             topic: "Created", origin: .local, cards: [card])
        localDecks.insert(deck, at: 0)
        put("localDecks", localDecks)
    }
}