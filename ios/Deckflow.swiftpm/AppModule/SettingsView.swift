import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: DeckflowStore
    @State private var newRepository = ""
    @State private var newBranch = "main"
    @State private var notificationsEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(DeckPalette.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private by default")
                            Text("Progress and imported decks stay on this device.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Study preferences") {
                    Picker("Daily study target", selection: Binding(get: { store.dailyGoal }, set: { store.setGoal($0) })) {
                        ForEach([10, 15, 20, 30], id: \.self) { Text("\($0) minutes").tag($0) }
                    }
                    Picker("Preferred language", selection: Binding(get: { store.preferredLanguage }, set: { store.setLanguage($0) })) {
                        ForEach(["Spanish", "French", "English", "Japanese", "German", "Italian", "Portuguese", "Sanskrit", "Other"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    Toggle("Dark appearance", isOn: Binding(get: { store.darkMode }, set: { store.setDark($0) }))
                    Toggle("Daily study reminder", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in Task { await setReminder(enabled) } }
                }
                Section("GitHub deck source") {
                    TextField("owner/repository", text: $newRepository)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("branch", text: $newBranch)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Save repository & sync") {
                        store.setRepository(newRepository, branch: newBranch)
                        Task { await store.sync() }
                    }
                    .disabled(!GitHubDeckService.validRepository(newRepository) || newBranch.clean.isEmpty)
                    Label("Only public CSV decks are downloaded from GitHub.", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Library") {
                    LabeledContent("GitHub decks", value: "\(store.catalog.count)")
                    LabeledContent("Personal decks", value: "\(store.localDecks.count)")
                    LabeledContent("Learned cards", value: "\(store.learnedCount)")
                    Button {
                        Task { await store.sync() }
                    } label: { Label("Sync decks now", systemImage: "arrow.clockwise") }
                }
                Section("About") {
                    LabeledContent("App", value: "Deckflow for iOS")
                    LabeledContent("Built with", value: "SwiftUI · Apple frameworks")
                    Text("No account, advertisements, or third-party UI libraries required.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                newRepository = store.repository
                newBranch = store.branch
                UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
                    Task { @MainActor in notificationsEnabled = pending.contains(where: { $0.identifier == "deckflow.daily" }) }
                }
            }
        }
    }

    private func setReminder(_ enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: ["deckflow.daily"])
            return
        }
        do {
            let allowed = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard allowed else { notificationsEnabled = false; return }
            let content = UNMutableNotificationContent()
            content.title = "Time for Deckflow"
            content.body = "Your next flashcard is ready. Keep your daily learning streak going!"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 19, minute: 0), repeats: true)
            let request = UNNotificationRequest(identifier: "deckflow.daily", content: content, trigger: trigger)
            try await center.add(request)
        } catch {
            notificationsEnabled = false
            store.message = "Couldn't set study reminder: \(error.localizedDescription)"
        }
    }
}