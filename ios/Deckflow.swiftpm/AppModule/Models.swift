import Foundation

struct Flashcard: Codable, Hashable, Identifiable {
    var front: String
    var back: String
    var example: String = ""
    var exampleTranslation: String = ""
    var note: String = ""
    var level: String = ""
    var type: String = ""
    var audioLanguage: String = ""

    // Stable across app launches; not based on randomized Swift Hasher.
    var id: String { front + "\u{001F}" + back }
}

enum DeckOrigin: String, Codable { case github, local }

struct StudyDeck: Identifiable, Codable, Hashable {
    var id: String               // GitHub path or locally generated UUID
    var title: String
    var subject: String
    var topic: String
    var sha: String = ""
    var origin: DeckOrigin = .github
    var cards: [Flashcard]? = nil
    var language: String = ""

    var itemCount: Int? { cards?.count }
    var symbol: String {
        switch subject.lowercased() {
        case "languages": return "character.bubble"
        case "mathematics": return "function"
        case "science": return "atom"
        case "spirituality": return "sparkles"
        case "history": return "building.columns"
        case "technology", "programming": return "laptopcomputer"
        default: return "rectangle.stack"
        }
    }
}

struct SavedSession: Codable {
    var deckID: String
    var index: Int
    var cardID: String
    var showTranslation: Bool
    var levelFilter: String
    var typeFilter: String
    var order: [String]
}

struct GitHubTree: Decodable {
    var tree: [GitHubTreeEntry]
    var truncated: Bool
}
struct GitHubTreeEntry: Decodable {
    var path: String
    var type: String
    var sha: String?
}

enum DeckflowError: LocalizedError {
    case invalidRepository, invalidCSV, noCards, badResponse(Int), invalidDocument
    var errorDescription: String? {
        switch self {
        case .invalidRepository: "Use a public GitHub repository in owner/name format."
        case .invalidCSV: "CSV must include front/back, french/meaning, or question/answer columns."
        case .noCards: "No usable flashcards were found in this CSV."
        case .badResponse(let code): "GitHub returned HTTP \(code). Check the connection or repository."
        case .invalidDocument: "This file isn't valid UTF-8 CSV text."
        }
    }
}

extension String {
    var clean: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var prettyDeckName: String {
        var value = self
        if value.lowercased().hasSuffix(".csv") { value = String(value.dropLast(4)) }
        for suffix in ["_Deck", "_Cards", "_Flashcards"] where value.lowercased().hasSuffix(suffix.lowercased()) {
            value = String(value.dropLast(suffix.count))
        }
        return value.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ").clean
    }
}