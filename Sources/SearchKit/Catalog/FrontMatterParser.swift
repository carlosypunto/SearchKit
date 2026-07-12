import Foundation

/// Minimal front-matter parser for corpus files:
///
/// ```
/// ---
/// id: es-swift-optionals
/// title: Optionals en Swift
/// language: es
/// family: swift-fundamentals
/// ---
/// body…
/// ```
enum FrontMatterParser {
    struct Parsed {
        let fields: [String: String]
        let body: String
    }

    enum ParseError: Error, Equatable {
        case missingFrontMatter
        case missingField(String)
    }

    static func parse(_ raw: String) throws -> Parsed {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            throw ParseError.missingFrontMatter
        }
        var fields: [String: String] = [:]
        var bodyStart: Int? = nil
        for (index, line) in lines.enumerated().dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" {
                bodyStart = index + 1
                break
            }
            guard let colon = trimmed.firstIndex(of: ":") else { continue }
            let key = String(trimmed[..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { fields[key] = value }
        }
        guard let bodyStart else { throw ParseError.missingFrontMatter }
        let body = lines[bodyStart...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return Parsed(fields: fields, body: body)
    }

    /// Builds a `SearchDocument` from a raw corpus file. The content hash
    /// covers the full raw file so metadata edits also invalidate the document.
    static func document(fromRaw raw: String, fallbackID: String) throws -> SearchDocument {
        let parsed = try parse(raw)
        guard let title = parsed.fields["title"] else { throw ParseError.missingField("title") }
        guard let language = parsed.fields["language"] else { throw ParseError.missingField("language") }
        return SearchDocument(
            id: parsed.fields["id"] ?? fallbackID,
            title: title,
            language: language,
            family: parsed.fields["family"] ?? "general",
            body: parsed.body,
            contentHash: SearchDocument.hash(of: raw)
        )
    }
}
