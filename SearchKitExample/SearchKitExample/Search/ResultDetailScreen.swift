import SwiftUI
import SearchKit

struct ResultDetailScreen: View {
    let candidate: SearchCandidate
    let ragPrompt: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.title)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("\(candidate.documentID)  ·  fragment \(candidate.ordinal)  ·  \(candidate.family)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(candidate.bodyText)
                    .font(.body)
                    .textSelection(.enabled)

                DisclosureGroup("Prompt improved by RAG") {
                    Text(ragPrompt)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                }
                .font(.headline)
                .accessibilityHint("Expands to show the full RAG prompt built from this result.")
            }
            .padding()
        }
        .navigationTitle("Result")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
