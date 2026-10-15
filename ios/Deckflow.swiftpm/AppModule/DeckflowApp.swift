import SwiftUI
import UniformTypeIdentifiers

@main
struct DeckflowApp: App {
    @StateObject private var store = DeckflowStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(store.darkMode ? .dark : .light)
                .task { await store.initialize() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: DeckflowStore
    @State private var tab = 1
    @State private var importing = false
    @State private var showingCreate = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView(selection: $tab) {
            HomeView(openLibrary: { tab = 1 }, importing: $importing, showingCreate: $showingCreate)
                .tabItem { Label("Home", systemImage: "house") }.tag(0)
            LibraryView(importing: $importing, showingCreate: $showingCreate)
                .tabItem { Label("Library", systemImage: "square.stack.3d.up") }.tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(2)
        }
        .tint(DeckPalette.blue)
        .background(DeckPalette.background)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let first = urls.first else { return }
                do { try store.importCSV(from: first); tab = 1 }
                catch { store.message = "Couldn't import CSV: \(error.localizedDescription)" }
            case .failure(let error): store.message = error.localizedDescription
            }
        }
        .sheet(isPresented: $showingCreate) { CreateDeckSheet() }
        .sheet(item: $store.previewDeck) { deck in DeckPreviewSheet(deck: deck) }
        .fullScreenCover(isPresented: $store.isStudying) { StudyView() }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView { showingOnboarding = false }
        }
        .task { if !store.hasOnboarded { showingOnboarding = true } }
        .alert("Deckflow", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("OK", role: .cancel) { store.message = nil }
        } message: { Text(store.message ?? "") }
    }
}