import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DeckflowStore
    let openLibrary: () -> Void
    @Binding var importing: Bool
    @Binding var showingCreate: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    welcome
                    if let recent = store.activeDeck { continueCard(recent) }
                    progressCard
                    quickActions
                    if !store.featuredDecks.isEmpty {
                        VStack(alignment: .leading, spacing: 13) {
                            SectionCaption(title: "Recommended for you")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(store.featuredDecks.prefix(5)) { deck in
                                        Button { Task { await store.preview(deck) } } label: {
                                            FeaturedDeckCard(deck: deck, learned: store.learnedFor(deck))
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(DeckPalette.screenGradient.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEARN A LITTLE EVERY DAY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(2).foregroundStyle(DeckPalette.muted)
            Text("Learn anything.\nRemember everything.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .tracking(-0.7).foregroundStyle(.white)
            Text("Your flashcards, languages and topics — in one calm place.")
                .font(.subheadline).foregroundStyle(DeckPalette.muted)
            HStack(spacing: 9) {
                Label("Apple native", systemImage: "apple.logo")
                Label("Offline progress", systemImage: "checkmark.shield")
            }
            .font(.caption2).foregroundStyle(.white.opacity(0.8))
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(colors: [DeckPalette.violet.opacity(0.3), DeckPalette.blue.opacity(0.11), DeckPalette.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 23)
        )
        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(DeckPalette.stroke))
    }

    private func continueCard(_ deck: StudyDeck) -> some View {
        NativePanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionCaption(title: "Continue where you left off")
                HStack(spacing: 12) {
                    DeckThumbnail(symbol: deck.symbol, size: 46)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(deck.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                        Text("Card \(store.cardIndex + 1) of \(max(store.visibleCards.count, 1))")
                            .font(.caption).foregroundStyle(DeckPalette.muted)
                    }
                    Spacer()
                }
                Button {
                    store.isStudying = true
                } label: { Label("Resume studying", systemImage: "play.fill") }
                    .buttonStyle(PrimaryActionStyle())
            }.padding(16)
        }
    }

    private var progressCard: some View {
        NativePanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionCaption(title: "Your daily progress")
                HStack(alignment: .center, spacing: 17) {
                    ZStack {
                        Circle().stroke(DeckPalette.elevated, lineWidth: 8)
                        Circle().trim(from: 0, to: min(1, CGFloat(store.completedToday) / CGFloat(max(1, store.dailyGoal))))
                            .stroke(DeckPalette.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(store.completedToday)")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                    }.frame(width: 84, height: 84)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("New cards learned today").font(.subheadline.weight(.medium))
                        Text("\(store.learnedCount) cards learned overall")
                            .font(.caption).foregroundStyle(DeckPalette.muted)
                        Text("Daily target: \(store.dailyGoal) cards")
                            .font(.caption).foregroundStyle(DeckPalette.muted)
                    }
                    Spacer(minLength: 0)
                }
            }.padding(18)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionCaption(title: "Start learning")
            HStack(spacing: 11) {
                quickButton("Browse decks", icon: "square.stack.3d.up", action: openLibrary)
                quickButton("Import CSV", icon: "square.and.arrow.down", action: { importing = true })
                quickButton("Create deck", icon: "plus.rectangle.on.folder", action: { showingCreate = true })
            }
        }
    }

    private func quickButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 9) {
                Image(systemName: icon).font(.title3).foregroundStyle(DeckPalette.blue)
                Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 17)
            .background(DeckPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}