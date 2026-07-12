import Foundation
import Testing
@testable import SearchKit

@Suite("PromptBuilder")
struct PromptBuilderTests {

    private var candidate: SearchCandidate {
        SearchCandidate(
            id: 1, documentID: "doc-1", title: "Concurrencia en Swift", language: "es",
            family: "swift", ordinal: 0,
            content: "Concurrencia en Swift\n\nLos actores aíslan estado.", score: 1
        )
    }

    @Test func spanishPromptContainsContextAndQuestion() {
        let prompt = PromptBuilder().prompt(question: "¿Qué es un actor?", candidates: [candidate], language: .spanish)
        #expect(prompt.contains("CONTEXTO:"))
        #expect(prompt.contains("PREGUNTA: ¿Qué es un actor?"))
        #expect(prompt.contains("Los actores aíslan estado."))
        #expect(prompt.contains("[Concurrencia en Swift — doc-1#0]"))
    }

    @Test func englishPromptUsesEnglishTemplate() {
        let prompt = PromptBuilder().prompt(question: "What is an actor?", candidates: [candidate], language: .english)
        #expect(prompt.contains("CONTEXT:"))
        #expect(prompt.contains("QUESTION: What is an actor?"))
        #expect(prompt.contains("I don't know"))
    }
}
