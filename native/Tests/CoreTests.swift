import Foundation

@main
struct CoreTests {
    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
    }
    static func main() throws {
        // Quoted commas, quotes, multilingual Unicode, quoted newlines, and Windows line endings.
        let csv = "front,back,example,example_translation,note,level,type,audio_lang\r\n" +
            "\"Hola, amigo\",\"Hello, friend\",\"¿Qué tal?\",\"How are you?\",\"He said \"\"hola\"\".\",A1,Greeting,es-ES\r\n" +
            "\"धर्म\nक्षेत्रे\",Duty,,,,18,Shloka,hi-IN\r\n"
        let cards = try CSVDeckParser.parse(csv)
        check(cards.count == 2, "multiline CSV row count")
        check(cards[0].front == "Hola, amigo", "CSV quoted comma")
        check(cards[0].note == "He said \"hola\".", "CSV escaped quotes")
        check(cards[1].front == "धर्म\nक्षेत्रे", "Sanskrit quoted newlines")
        check(cards[0].audioLanguage == "es-ES", "audio locale")
        let french = try CSVDeckParser.parse("category,level,french,meaning,example_fr,example_en,note\nGreetings,A1,Bonjour,Hello,Bonjour Paul,Hello Paul,Everyday greeting\n")
        check(french.count == 1 && french[0].back == "Hello", "legacy French deck headers")
        let spanish = GitHubDeckService.classify(path: "decks/Languages/Spanish/Spanish_A1_Essentials.csv", sha: "abc")
        check(spanish.subject == "Languages" && spanish.topic == "Spanish", "Spanish GitHub hierarchy")
        let gita = GitHubDeckService.classify(path: "decks/Spirituality/Bhagavad_Gita/Adhyaya_18.csv", sha: "abc")
        check(gita.subject == "Spirituality" && gita.topic == "Bhagavad Gita", "Gita subject classification")
        let roman = GitHubDeckService.classify(path: "decks/Mathematics/Roman_Numerals/Learn_Roman_Numerals.csv", sha: "abc")
        check(roman.subject == "Mathematics" && roman.topic == "Roman Numerals", "Roman numerals classification")
        check(GitHubDeckService.validRepository("0PAtelDhruV0/Flashcard_app"), "valid repository")
        check(!GitHubDeckService.validRepository("oops"), "invalid repository")
        check(!GitHubDeckService.validRepository("owner/repo/extra"), "malformed repository")
        let baseCard = Flashcard(front: "Buenos días", back: "Good morning")
        let encoded = try JSONEncoder().encode(baseCard)
        let decoded = try JSONDecoder().decode(Flashcard.self, from: encoded)
        check(decoded.id == baseCard.id, "stable card identity after persistence")
        check(CSVDeckParser.escape("a,b") == "\"a,b\"", "CSV escaping")
        print("PASS: 13 Deckflow core checks (parsing, Unicode, legacy headers, discovery, persistence)")
    }
}