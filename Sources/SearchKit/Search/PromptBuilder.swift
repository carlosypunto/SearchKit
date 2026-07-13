import Foundation

/// Builds a grounded RAG prompt from retrieved candidates. Pure function: no
/// store access, no LLM call — the caller forwards the prompt to a model.
public struct PromptBuilder: Sendable {

    /// Language of the prompt's fixed instructions (not of the candidates).
    public enum PromptLanguage: String, Sendable {
        /// Spanish instructions and "No lo sé" refusal.
        case spanish = "es"
        /// English instructions and "I don't know" refusal.
        case english = "en"
    }

    /// Creates the builder (stateless).
    public init() {}

    /// Builds a grounded prompt: instructions, the candidates as labeled
    /// context blocks, and the question.
    ///
    /// - Parameters:
    ///   - question: The user's question, embedded verbatim.
    ///   - candidates: Chunks to ground the answer in; each block is labeled
    ///     `[title — documentID#ordinal]` so answers can cite sources.
    ///   - language: Language of the fixed instructions.
    /// - Returns: The complete prompt, ready to send to an LLM.
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
