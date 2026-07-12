import Foundation

/// Source of catalog documents. Implementations own storage (bundle, files,
/// app database) and must never depend on the search index.
public protocol CatalogRepository: Sendable {
    func documents() async throws -> [SearchDocument]
}
