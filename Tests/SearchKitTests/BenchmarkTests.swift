import Foundation
import Testing
@testable import SearchKit

/// Local benchmark over the target catalog size (500 documents) using the
/// fake provider — measures store/pipeline overhead, not the NL model.
@Suite("Benchmark", .tags(.benchmark))
struct BenchmarkTests {

    @Test func targetCatalogIngestionAndQuery() async throws {
        try await withTemporaryDatabase { dbURL in
            let topics = ["swift", "actores", "tablas", "vectores", "redes", "docker", "git", "pruebas"]
            let documents = (0..<500).map { index in
                let topic = topics[index % topics.count]
                let body = (0..<120)
                    .map { "\(topic) palabra\($0 % 40) relleno\(index % 10)" }
                    .joined(separator: " ")
                return makeDocument(id: "doc-\(index)", title: "Lección \(index) de \(topic)", body: body)
            }

            let stack = try await makeSearchStack(dbURL: dbURL)

            let ingestStart = ContinuousClock.now
            try await stack.service.sync(documents: documents)
            let ingestDuration = ContinuousClock.now - ingestStart

            let queryStart = ContinuousClock.now
            let outcome = try await stack.service.search("actores concurrencia palabra3", topK: 10)
            let queryDuration = ContinuousClock.now - queryStart

            #expect(try await stack.indexStore.chunkCount() >= 500)
            #expect(!outcome.candidates.isEmpty)

            print("[benchmark] 500-doc ingest: \(ingestDuration), hybrid query: \(queryDuration)")
            // Generous sanity bounds (local machine, debug build).
            #expect(ingestDuration < .seconds(60))
            #expect(queryDuration < .seconds(2))
        }
    }
}

extension Tag {
    @Tag static var benchmark: Tag
}
