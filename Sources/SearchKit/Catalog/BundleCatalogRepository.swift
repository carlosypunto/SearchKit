import Foundation

/// Reads the corpus from a bundle: every `.md` resource with front matter.
/// With Xcode's synchronized folders resources are flattened into the bundle
/// root, so lookup does not rely on a subdirectory unless one is provided.
public struct BundleCatalogRepository: CatalogRepository {
    private let bundle: Bundle
    private let fileExtension: String
    private let subdirectory: String?

    public init(bundle: Bundle = .main, fileExtension: String = "md", subdirectory: String? = nil) {
        self.bundle = bundle
        self.fileExtension = fileExtension
        self.subdirectory = subdirectory
    }

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
