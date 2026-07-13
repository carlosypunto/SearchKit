import Foundation

/// Reads the corpus from a bundle: every `.md` resource with front matter.
/// With Xcode's synchronized folders resources are flattened into the bundle
/// root, so lookup does not rely on a subdirectory unless one is provided.
public struct BundleCatalogRepository: CatalogRepository {
    private let bundle: Bundle
    private let fileExtension: String
    private let subdirectory: String?

    /// Creates a repository over a bundle.
    ///
    /// - Parameters:
    ///   - bundle: Bundle to read resources from.
    ///   - fileExtension: Resource extension to load (default "md").
    ///   - subdirectory: Bundle subdirectory, or nil for the bundle root
    ///     (where Xcode's synchronized folders flatten resources).
    public init(bundle: Bundle = .main, fileExtension: String = "md", subdirectory: String? = nil) {
        self.bundle = bundle
        self.fileExtension = fileExtension
        self.subdirectory = subdirectory
    }

    /// Reads and parses every matching resource, sorted by file name so the
    /// catalog order is deterministic.
    ///
    /// - Returns: One ``SearchDocument`` per resource; the file name (without
    ///   extension) is the fallback `id` when front matter omits one.
    /// - Throws: File-reading errors, or front-matter parsing errors.
    public func documents() async throws -> [SearchDocument] {
        let urls = bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: subdirectory) ?? []
        var documents: [SearchDocument] = []
        documents.reserveCapacity(urls.count)
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let raw = try String(contentsOf: url, encoding: .utf8)
            let fallbackID = url.deletingPathExtension().lastPathComponent
            documents.append(try FrontMatterParser.document(fromRaw: raw, fallbackID: fallbackID))
        }
        return documents
    }
}
