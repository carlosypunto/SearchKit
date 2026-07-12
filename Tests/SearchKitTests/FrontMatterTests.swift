import Foundation
import Testing
@testable import SearchKit

@Suite("FrontMatter")
struct FrontMatterTests {

    private let sample = """
    ---
    id: es-swift-optionals
    title: Optionals en Swift
    language: es
    family: swift-fundamentals
    ---
    Los opcionales representan la ausencia de valor.
    """

    @Test func parsesFieldsAndBody() throws {
        let document = try FrontMatterParser.document(fromRaw: sample, fallbackID: "fallback")
        #expect(document.id == "es-swift-optionals")
        #expect(document.title == "Optionals en Swift")
        #expect(document.language == "es")
        #expect(document.family == "swift-fundamentals")
        #expect(document.body == "Los opcionales representan la ausencia de valor.")
        #expect(document.contentHash == SearchDocument.hash(of: sample))
    }

    @Test func usesFallbackIDWhenMissing() throws {
        let raw = """
        ---
        title: Sin id
        language: en
        ---
        Body text.
        """
        let document = try FrontMatterParser.document(fromRaw: raw, fallbackID: "file-name")
        #expect(document.id == "file-name")
        #expect(document.family == "general")
    }

    @Test func missingFrontMatterThrows() {
        #expect(throws: FrontMatterParser.ParseError.missingFrontMatter) {
            _ = try FrontMatterParser.document(fromRaw: "no front matter", fallbackID: "x")
        }
    }

    @Test func missingTitleThrows() {
        let raw = """
        ---
        language: es
        ---
        Body.
        """
        #expect(throws: FrontMatterParser.ParseError.missingField("title")) {
            _ = try FrontMatterParser.document(fromRaw: raw, fallbackID: "x")
        }
    }
}
