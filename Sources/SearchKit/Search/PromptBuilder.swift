import Foundation

/// Builds a grounded RAG prompt from retrieved candidates. Pure function: no
/// store access, no LLM call — the caller forwards the prompt to a model.
public struct PromptBuilder: Sendable {

    public enum PromptLanguage: String, Sendable {
        case spanish = "es"
        case english = "en"
    }

    public init() {}

    public func prompt(
        question: String,
        candidates: [SearchCandidate],
        language: PromptLanguage = .spanish
    ) -> String {
        let context = candidates
            .map { "[\($0.title) — \($0.documentID)#\($0.ordinal)]\n\($0.content)" }
            .joined(separator: "\n\n---\n\n")

        switch language {
        case .spanish:
            return """
            Usa únicamente el contexto siguiente para responder.
            Si la respuesta no está en el contexto, di "No lo sé".

            CONTEXTO:
            \(context)

            PREGUNTA: \(question)
            """
        case .english:
            return """
            Answer using only the context below.
            If the answer is not in the context, say "I don't know".

            CONTEXT:
            \(context)

            QUESTION: \(question)
            """
        }
    }
}
