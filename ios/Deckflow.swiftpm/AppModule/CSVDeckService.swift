import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// CSV support includes quoted commas, double quotes, Windows line endings and quoted newlines.
enum CSVDeckParser {
    static func readRows(_ text: String) -> [[String]] {
        let source = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        var rows: [[String]] = [], row: [String] = [], field = "", quoted = false
        var index = source.startIndex
        while index < source.endIndex {
            let char = source[index]
            let next = source.index(after: index)
            if quoted {
                if char == "\"" {
                    if next < source.endIndex && source[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else { quoted = false }
                } else { field.append(char) }
            } else if char == "\"" { quoted = true }
            else if char == "," { row.append(field); field = "" }
            else if char == "\n" || char == "\r" || char == "\r\n" {
                row.append(field)
                if row.contains(where: { !$0.clean.isEmpty }) { rows.append(row) }
                row = []; field = ""
                if char == "\r" && next < source.endIndex && source[next] == "\n" { index = next }
            } else { field.append(char) }
            index = source.index(after: index)
        }
        row.append(field)
        if row.contains(where: { !$0.clean.isEmpty }) { rows.append(row) }
        return rows
    }

    static func parse(_ csv: String) throws -> [Flashcard] {
        var rows = readRows(csv)
        guard !rows.isEmpty else { throw DeckflowError.noCards }
        let header = rows.removeFirst().map {
            $0.clean.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
        }
        let aliases: [String: [String]] = [
            "front": ["front", "french", "spanish", "sanskrit", "question", "word", "term", "prompt", "text", "phrase", "expression"],
            "back": ["back", "meaning", "english", "answer", "translation", "definition", "response", "explanation"],
            "example": ["example", "example_fr", "example_es", "example_front", "example_sentence"],
            "exampleTranslation": ["example_translation", "example_en", "example_back", "example_meaning"],
            "note": ["note", "notes", "tip", "hint", "details"],
            "level": ["level", "difficulty", "cefr"],
            "type": ["type", "category", "card_type"],
            "audioLanguage": ["audio_lang", "voice_lang", "tts_lang", "locale", "speech_language"]
        ]
        func col(_ field: String) -> Int? { header.firstIndex(where: { aliases[field, default: []].contains($0) }) }
        guard let front = col("front"), let back = col("back") else { throw DeckflowError.invalidCSV }
        func field(_ row: [String], _ key: String) -> String {
            guard let c = col(key), c < row.count else { return "" }
            return row[c].clean
        }
        let cards = rows.compactMap { row -> Flashcard? in
            guard front < row.count, back < row.count else { return nil }
            let f = row[front].clean, b = row[back].clean
            guard !f.isEmpty && !b.isEmpty else { return nil }
            return Flashcard(front: f, back: b, example: field(row, "example"),
                             exampleTranslation: field(row, "exampleTranslation"),
                             note: field(row, "note"), level: field(row, "level"),
                             type: field(row, "type"), audioLanguage: field(row, "audioLanguage"))
        }
        guard !cards.isEmpty else { throw DeckflowError.noCards }
        return cards
    }

    static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

enum GitHubDeckService {
    static func discover(repository: String, branch: String) async throws -> [StudyDeck] {
        guard validRepository(repository) else { throw DeckflowError.invalidRepository }
        let url = URL(string: "https://api.github.com/repos/\(repository)/git/trees/\(branch)?recursive=1")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response)
        let tree = try JSONDecoder().decode(GitHubTree.self, from: data)
        guard !tree.truncated else { throw DeckflowError.invalidRepository }
        var found: [String: StudyDeck] = [:]
        for entry in tree.tree where entry.type == "blob" && entry.path.lowercased().hasSuffix(".csv") {
            let path = entry.path
            let base = String(path.split(separator: "/").last ?? "")
            let lower = base.lowercased()
            if ["all_decks", "combined", "template", "sample", "backup", "all_levels", "all_topic_decks"].contains(where: { lower.contains($0) }) { continue }
            let deck = classify(path: path, sha: entry.sha ?? "")
            let identity = [deck.subject, deck.topic, deck.title].joined(separator: "|").lowercased()
            if let previous = found[identity], previous.id.hasPrefix("decks/") { continue }
            found[identity] = deck
        }
        return found.values.sorted {
            [$0.subject, $0.topic, $0.title].joined(separator: "|").localizedStandardCompare([$1.subject, $1.topic, $1.title].joined(separator: "|")) == .orderedAscending
        }
    }

    static func download(_ deck: StudyDeck, repository: String, branch: String) async throws -> [Flashcard] {
        let segments = deck.id.split(separator: "/").map(String.init)
        guard !segments.contains("..") else { throw DeckflowError.invalidRepository }
        let encoded = segments.map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? $0 }.joined(separator: "/")
        let url = URL(string: "https://raw.githubusercontent.com/\(repository)/\(branch)/\(encoded)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response)
        guard let text = String(data: data, encoding: .utf8) else { throw DeckflowError.invalidDocument }
        return try CSVDeckParser.parse(text)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else { throw DeckflowError.badResponse(0) }
        guard (200...299).contains(response.statusCode) else { throw DeckflowError.badResponse(response.statusCode) }
    }

    static func validRepository(_ value: String) -> Bool {
        let parts = value.split(separator: "/")
        return parts.count == 2 && parts.allSatisfy {
            !$0.isEmpty && $0.unicodeScalars.allSatisfy { CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-").contains($0) }
        }
    }

    static func classify(path: String, sha: String) -> StudyDeck {
        var parts = path.split(separator: "/").map(String.init)
        let base = parts.popLast() ?? path
        let folder = parts.filter { !["decks", "cards", "flashcards", "csv", "data", "french_flashcards_parlez_multilevel"].contains($0.lowercased()) }
        let title = base.prettyDeckName
        let langNames = ["French", "Spanish", "English", "Japanese", "German", "Korean", "Italian", "Portuguese", "Chinese", "Hindi", "Arabic", "Sanskrit"]
        if folder.first?.lowercased() == "languages" {
            let language = folder.count > 1 ? folder[1].prettyDeckName : "Other"
            return StudyDeck(id: path, title: title, subject: "Languages", topic: language, sha: sha, language: language)
        }
        if let first = folder.first, langNames.contains(where: { $0.caseInsensitiveCompare(first) == .orderedSame }) {
            return StudyDeck(id: path, title: title, subject: "Languages", topic: first.prettyDeckName, sha: sha, language: first.prettyDeckName)
        }
        if !folder.isEmpty {
            return StudyDeck(id: path, title: title, subject: folder[0].prettyDeckName,
                             topic: folder.count > 1 ? folder[1].prettyDeckName : "General", sha: sha)
        }
        if let language = langNames.first(where: { title.lowercased().hasPrefix($0.lowercased() + " ") }) {
            return StudyDeck(id: path, title: String(title.dropFirst(language.count)).clean,
                             subject: "Languages", topic: language, sha: sha, language: language)
        }
        let words = title.split(separator: " ").map(String.init)
        return StudyDeck(id: path, title: title, subject: words.first ?? "Other", topic: "General", sha: sha)
    }
}