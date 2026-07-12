import Foundation
import Testing
@testable import SearchKit

@Suite("Concurrency")
struct ConcurrencyTests {

    @Test func parallelSearchesReturnConsistentResults() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: (0..<20).map { index in
                makeDocument(id: "doc-\(index)", title: "Documento \(index)", body: "tema\(index) contenido compartido común")
            })

            let outcomes = try await withThrowingTaskGroup(of: SearchOutcome.self) { group in
                for index in 0..<20 {
                    group.addTask { [service = stack.service] in
                        try await service.search("tema\(index) contenido")
                    }
                }
                var collected: [SearchOutcome] = []
                for try await outcome in group {
                    collected.append(outcome)
                }
                return collected
            }
            #expect(outcomes.count == 20)
            #expect(outcomes.allSatisfy { !$0.candidates.isEmpty })
        }
    }
}
