import SwiftUI

struct CreateDeckSheet: View {
    @EnvironmentObject private var store: DeckflowStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var subject = "My Decks"
    @State private var front = ""
    @State private var back = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck") {
                    TextField("Deck title", text: $title)
                    TextField("Subject", text: $subject)
                }
                Section("First flashcard") {
                    TextField("Word, question or sentence", text: $front, axis: .vertical)
                        .lineLimit(2...6)
                    TextField("Translation or answer", text: $back, axis: .vertical)
                        .lineLimit(2...6)
                }
                Section {
                    Label("You can import multi-card decks as CSV files from the Library tab.", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createDeck(title: title, subject: subject, front: front, back: back)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.clean.isEmpty || front.clean.isEmpty || back.clean.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}