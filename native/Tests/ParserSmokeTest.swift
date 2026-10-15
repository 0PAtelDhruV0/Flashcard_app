import Foundation

@main
struct ParserSmokeTest {
    static func main() throws {
        let csv = "front,back,example,example_translation,note,level,type,audio_lang\r\n\"Hola, amigo\",Hello friend,\"Dijo \"\"hola\"\"\",\"He said hello\",,A1,Greetings,es-ES\r\n\"सर्वधर्मान्परित्यज्य\nमामेकं शरणं व्रज\",\"Seek refuge\",,,,A1,Shloka,hi-IN\r\n"
        let cards = try CSVDeckParser.parse(csv)
        precondition(cards.count == 2, "Expected 2 cards")
        precondition(cards[0].front == "Hola, amigo")
        precondition(cards[0].example == "Dijo \"hola\"")
        precondition(cards[1].front.contains("\n"))
        let path = "decks/Languages/Spanish/Spanish_A1_Essentials.csv"
        let deck = GitHubDeckService.classify(path: path, sha: "abc")
        precondition(deck.subject == "Languages" && deck.topic == "Spanish")
        let math = GitHubDeckService.classify(path: "decks/Mathematics/Roman_Numerals/Learn_Roman_Numerals.csv", sha: "")
        precondition(math.subject == "Mathematics" && math.topic == "Roman Numerals")
        print("Passed: quoted CSV, multiline Sanskrit, GitHub Spanish, Roman numerals classification")
    }
}