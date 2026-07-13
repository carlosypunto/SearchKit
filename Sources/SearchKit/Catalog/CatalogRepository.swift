import Foundation

/// Source of catalog documents. Implementations own storage (bundle, files,
/// app database) and must never depend on the search index.
public protocol CatalogRepository: Sendable {
    /// Loads the full current catalog.
    ///
    /// - Returns: Every document in the catalog; `SearchService.sync` diffs
    ///   them by `contentHash` against the index.
    /// - Throws: Any storage/parsing error of the concrete implementation.
    func documents() async throws -> [SearchDocument]
}
