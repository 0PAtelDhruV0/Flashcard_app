import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: DeckflowStore
    @Binding var importing: Bool
    @Binding var showingCreate: Bool
    @State private var query = ""
    @State private var selectedSubject = "All"
    @State private var expandedTopic: String?

    private var matching: [StudyDeck] {
        store.allDecks.filter { deck in
            (selectedSubject == "All" || deck.subject == selectedSubject)
            && (query.clean.isEmpty || [deck.title, deck.subject, deck.topic].joined(separator: " ").localizedCaseInsensitiveContains(query.clean))
        }
    }

    private var grouped: [(String, [StudyDeck])] {
        let groups = Dictionary(grouping: matching, by: { $0.topic })
        return groups.keys.sorted().map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    searchBar
                    categoryChips
                    if store.isSyncing && store.catalog.isEmpty {
                        HStack { ProgressView(); Text("Loading GitHub decks…").font(.subheadline).foregroundStyle(DeckPalette.muted) }
                            .frame(maxWidth: .infinity).padding(.vertical, 44)
                    } else if store.allDecks.isEmpty {
                        emptyState
                    } else {
                        featuredSection
                        if !query.clean.isEmpty { SectionCaption(title: "Search results", accessory: "\(matching.count) decks") }
                        topicGroups
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
            .background(DeckPalette.screenGradient.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await store.sync() } } label: {
                        Image(systemName: "arrow.clockwise").rotationEffect(.degrees(store.isSyncing ? 90 : 0))
                    }.accessibilityLabel("Sync from GitHub")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import CSV from Files", systemImage: "square.and.arrow.down") { importing = true }
                        Button("Create a deck", systemImage: "plus.rectangle.on.folder") { showingCreate = true }
                    } label: { Image(systemName: "plus.circle.fill").font(.system(size: 20)) }
                        .accessibilityLabel("Add deck")
                }
            }
            .refreshable { await store.sync() }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(DeckPalette.muted)
            TextField("Search decks, languages, topics…", text: $query)
                .font(.system(size: 14)).autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.foregroundStyle(DeckPalette.muted) }
        }
        .padding(.horizontal, 14).frame(height: 43)
        .background(DeckPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DeckPalette.stroke))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { selectedSubject = "All" } label: { MiniTag(title: "All", icon: "square.grid.2x2", active: selectedSubject == "All") }
                    .buttonStyle(.plain)
                ForEach(store.subjects, id: \.self) { subject in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { selectedSubject = subject } } label: {
                        MiniTag(title: subject, icon: icon(for: subject), active: selectedSubject == subject)
                    }.buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.trailing, 5)
    }

    @ViewBuilder
    private var featuredSection: some View {
        if !store.featuredDecks.isEmpty && query.clean.isEmpty && selectedSubject == "All" {
            VStack(alignment: .leading, spacing: 12) {
                SectionCaption(title: "Featured decks", accessory: "From your GitHub library")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(store.featuredDecks) { deck in
                            Button { Task { await store.preview(deck) } } label: {
                                FeaturedDeckCard(deck: deck, learned: store.learnedFor(deck))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var topicGroups: some View {
        VStack(spacing: 19) {
            ForEach(grouped, id: \.0) { topic, decks in
                VStack(alignment: .leading, spacing: 10) {
                    SectionCaption(title: topic, accessory: "\(decks.count) decks")
                    if decks.count < 4 {
                        ForEach(decks) { deck in row(deck) }
                    } else {
                        HStack(spacing: 12) {
                            ForEach(decks.prefix(2)) { deck in
                                Button { Task { await store.preview(deck) } } label: {
                                    FeaturedDeckCard(deck: deck, learned: store.learnedFor(deck))
                                }.buttonStyle(.plain)
                            }
                        }
                        Button(expandedTopic == topic ? "Show less" : "See all \(decks.count) decks") {
                            withAnimation { expandedTopic = expandedTopic == topic ? nil : topic }
                        }
                        .font(.caption.weight(.semibold)).foregroundStyle(DeckPalette.muted)
                        if expandedTopic == topic { ForEach(decks.dropFirst(2)) { deck in row(deck) } }
                    }
                }
            }
            if matching.isEmpty && !store.allDecks.isEmpty {
                ContentUnavailableView.search(text: query.isEmpty ? selectedSubject : query)
            }
        }
    }

    private func row(_ deck: StudyDeck) -> some View {
        Button { Task { await store.preview(deck) } } label: {
            HStack(spacing: 12) {
                DeckThumbnail(symbol: deck.symbol, size: 43)
                VStack(alignment: .leading, spacing: 3) {
                    Text(deck.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(2)
                    Text(deck.subject + " · " + deck.topic).font(.caption2).foregroundStyle(DeckPalette.muted)
                }
                Spacer(minLength: 6)
                if store.learnedFor(deck) > 0 {
                    Text("\(store.learnedFor(deck)) ✓").font(.caption2).foregroundStyle(.green)
                }
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(DeckPalette.muted)
            }
            .padding(11)
            .background(DeckPalette.surface, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack.badge.plus").font(.system(size: 55)).foregroundStyle(DeckPalette.blue)
            Text("Add a deck from your Library").font(.headline)
            Text("Import a CSV from Files or sync public decks from GitHub.")
                .font(.subheadline).foregroundStyle(DeckPalette.muted).multilineTextAlignment(.center)
            Button("Import a CSV") { importing = true }.buttonStyle(PrimaryActionStyle())
            Button("Sync GitHub") { Task { await store.sync() } }.font(.subheadline)
        }
        .frame(maxWidth: 390)
        .frame(maxWidth: .infinity).padding(.vertical, 90)
    }

    private func icon(for subject: String) -> String {
        switch subject.lowercased() {
        case "languages": "character.bubble"
        case "mathematics": "function"
        case "science": "atom"
        case "spirituality": "sparkles"
        case "history": "building.columns"
        default: "books.vertical"
        }
    }
}

struct FeaturedDeckCard: View {
    let deck: StudyDeck
    let learned: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            DeckThumbnail(symbol: deck.symbol, size: 61)
            Spacer(minLength: 15)
            Text(deck.title).font(.system(size: 13, weight: .semibold)).lineLimit(3)
            HStack(spacing: 5) {
                Image(systemName: "rectangle.stack.fill").font(.system(size: 9))
                Text(deck.itemCount.map { "\($0) cards" } ?? "GitHub deck")
                Spacer(minLength: 0)
                if learned > 0 { Text("\(learned) ✓").foregroundStyle(.green) }
            }
            .font(.system(size: 10)).foregroundStyle(DeckPalette.muted)
        }
        .foregroundStyle(.white)
        .padding(13)
        .frame(width: 166, height: 183, alignment: .topLeading)
        .background(DeckPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DeckPalette.stroke))
    }
}

struct DeckPreviewSheet: View {
    @EnvironmentObject private var store: DeckflowStore
    @Environment(\.dismiss) private var dismiss
    let deck: StudyDeck

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 13) {
                        DeckThumbnail(symbol: deck.symbol, size: 62)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deck.title).font(.system(size: 21, weight: .bold))
                            Text(deck.subject + " · " + deck.topic).font(.caption).foregroundStyle(DeckPalette.muted)
                        }
                    }
                    HStack(spacing: 9) {
                        MiniTag(title: "\(store.previewCards.count) cards", icon: "rectangle.stack")
                        MiniTag(title: "\(store.learnedFor(deck)) learned", icon: "checkmark")
                    }
                    SectionCaption(title: "Sample cards")
                    if store.previewLoading {
                        ProgressView("Loading flashcards…").padding(25)
                    } else if store.previewCards.isEmpty {
                        Text("Deck isn't available yet. Pull down in Library to retry.").foregroundStyle(DeckPalette.muted)
                    } else {
                        ForEach(Array(store.previewCards.prefix(3)), id: \.id) { card in
                            NativePanel {
                                VStack(alignment: .leading, spacing: 11) {
                                    Text(card.front).font(.system(size: 18, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                                    Divider().overlay(.white.opacity(0.08))
                                    Text(card.back).font(.system(size: 13)).foregroundStyle(DeckPalette.muted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).padding(17)
                            }
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(DeckPalette.background)
            .navigationTitle("Deck preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.toggleFavorite(deck)
                    } label: {
                        Image(systemName: store.favoriteDeckIDs.contains(deck.id) ? "heart.fill" : "heart")
                    }.accessibilityLabel("Favorite deck")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Study Deck") { Task { await store.beginStudy(deck) } }
                    .buttonStyle(PrimaryActionStyle())
                    .disabled(store.previewCards.isEmpty)
                    .padding(16)
                    .background(DeckPalette.background)
            }
        }
        .presentationDetents([.large])
    }
}