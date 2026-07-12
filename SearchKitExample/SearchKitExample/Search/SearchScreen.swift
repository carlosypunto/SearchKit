import SwiftUI
import SearchKit

struct SearchScreen: View {
    @State private var model = SearchViewModel()
    @State private var showsOptions = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Document Search")
                .toolbar {
                    ToolbarItem {
                        Button("Options", systemImage: "slider.horizontal.3") {
                            showsOptions = true
                        }
                        .disabled(!isReady)
                    }
                    ToolbarItem {
                        Button("Reindex", systemImage: "arrow.clockwise") {
                            Task { await model.reindexAll() }
                        }
                        .accessibilityHint("Deletes the search index and rebuilds it from the bundled corpus.")
                        .disabled(!isReady)
                    }
                }
                .navigationDestination(for: SearchCandidate.self) { candidate in
                    ResultDetailScreen(candidate: candidate, ragPrompt: model.ragPrompt(for: candidate))
                }
                .sheet(isPresented: $showsOptions) {
                    SearchOptionsSheet(model: model)
                }
        }
        .task {
            await model.start()
        }
    }

    private var isReady: Bool {
        if case .ready = model.indexState { return true }
        return false
    }

    @ViewBuilder
    private var content: some View {
        switch model.indexState {
        case .starting:
            ProgressView("Preparing index…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .indexing(let completed, let total):
            VStack(spacing: 12) {
                ProgressView(value: Double(completed), total: Double(max(total, 1)))
                    .frame(maxWidth: 320)
                Text("Indexing documents… \(completed)/\(total)")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Indexing documents")
            .accessibilityValue("\(completed) of \(total)")
        case .failed(let message):
            ContentUnavailableView {
                Label("Index unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await model.start() }
                }
            }
        case .ready(let chunkCount):
            ResultList(chunkCount: chunkCount, model: model)
        }
    }
}

private struct ResultList: View {
    let chunkCount: Int
    @Bindable var model: SearchViewModel

    /// Re-runs the debounced search when the query OR any option changes.
    private struct SearchRequestKey: Hashable {
        let query: String
        let mode: SearchMode
        let topK: Int
        let family: String?
        let language: String?
    }

    private var requestKey: SearchRequestKey {
        SearchRequestKey(
            query: model.query,
            mode: model.searchMode,
            topK: model.topK,
            family: model.familyFilter,
            language: model.languageFilter
        )
    }

    var body: some View {
        List {
            modeBanner
            if let error = model.searchErrorMessage {
                Label(error, systemImage: "xmark.octagon")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Error: \(error)"))
            }
            ForEach(model.results) { candidate in
                NavigationLink(value: candidate) {
                    ResultRow(candidate: candidate, mode: model.retrievalMode)
                }
            }
        }
        .overlay {
            if model.results.isEmpty {
                if model.query.isEmpty {
                    ContentUnavailableView(
                        "\(chunkCount) indexed fragments",
                        systemImage: "magnifyingglass",
                        description: Text("Enter a query in natural language, in Spanish or English.")
                    )
                } else {
                    ContentUnavailableView.search(text: model.query)
                }
            }
        }
        .searchable(text: $model.query, prompt: searchPrompt)
        .task(id: requestKey) {
            // Small debounce so we do not embed on every keystroke.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await model.search()
        }
    }

    /// An example query in the filtered language is more useful than one in
    /// the UI locale, so the es/en filters force a verbatim example; only the
    /// unfiltered case follows the app locale.
    private var searchPrompt: Text {
        switch model.languageFilter {
        case "es": Text(verbatim: "p. ej. cómo evitar data races")
        case "en": Text(verbatim: "e.g., how to avoid data races")
        default: Text("e.g., how to avoid data races")
        }
    }

    /// Orange warning only when `.auto` degraded; a forced mode gets a
    /// neutral informative label instead.
    @ViewBuilder
    private var modeBanner: some View {
        if let mode = model.retrievalMode {
            if model.requestedMode == .auto || model.requestedMode == nil {
                if mode != .hybrid {
                    Label(degradedModeText(mode), systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .accessibilityElement(children: .combine)
                }
            } else {
                Label("Forced mode: \(forcedModeText(mode))", systemImage: "slider.horizontal.3")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
            }
        }
    }

    private func degradedModeText(_ mode: RetrievalMode) -> String {
        switch mode {
        case .hybrid: ""
        case .textOnly: String(localized: "Degraded mode: lexical search only (embedding not available)")
        case .vectorOnly: String(localized: "Degraded mode: semantic search only")
        }
    }

    private func forcedModeText(_ mode: RetrievalMode) -> String {
        switch mode {
        case .hybrid: String(localized: "hybrid (RRF)")
        case .vectorOnly: String(localized: "vector")
        case .textOnly: String(localized: "text (BM25)")
        }
    }
}

private struct SearchOptionsSheet: View {
    @Bindable var model: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Retrieval") {
                    Picker("Mode", selection: $model.searchMode) {
                        Text("Auto").tag(SearchMode.auto)
                        Text("Hybrid").tag(SearchMode.hybrid)
                        Text("Vector").tag(SearchMode.vector)
                        Text("Text").tag(SearchMode.text)
                    }
                    Picker("Max results", selection: $model.topK) {
                        ForEach([5, 10, 20, 50], id: \.self) { value in
                            Text(value, format: .number).tag(value)
                        }
                    }
                }

                Section("Filters") {
                    Picker("Family", selection: $model.familyFilter) {
                        Text("All").tag(String?.none)
                        ForEach(model.availableFamilies, id: \.self) { family in
                            Text(family).tag(String?.some(family))
                        }
                    }
                    Picker("Language", selection: $model.languageFilter) {
                        Text("All").tag(String?.none)
                        Text("Spanish").tag(String?.some("es"))
                        Text("English").tag(String?.some("en"))
                    }
                }

                Section {
                    Picker("Distance Metric", selection: $model.distanceMetric) {
                        Text("Cosine").tag(IndexDistanceMetric.cosine)
                        Text("L2 (euclidean)").tag(IndexDistanceMetric.l2)
                    }
                } footer: {
                    Text("Changing the metric rebuilds the entire index (re-embedding the corpus).")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Search Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: model.distanceMetric) {
                Task { await model.applyDistanceMetricChange() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 400)
        #endif
    }
}

private struct ResultRow: View {
    let candidate: SearchCandidate
    let mode: RetrievalMode?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(candidate.title)
                    .font(.headline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                Spacer()
                Text(candidate.language.uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(candidate.language == "es" ? .orange.opacity(0.2) : .blue.opacity(0.2))
                    .clipShape(Capsule())
            }
            Text(candidate.snippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            Text(verbatim: "\(candidate.family)  ·  \(rankingText)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        // One element per row; the raw ranking numbers are visual detail, so
        // VoiceOver gets title + language + snippet instead.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(candidate.title), \(languageName), \(candidate.snippet)"))
    }

    private var languageName: String {
        candidate.language == "es" ? String(localized: "Spanish") : String(localized: "English")
    }

    /// Scores are not comparable across modes; label each with its semantics.
    private var rankingText: String {
        let score = candidate.score.formatted(.number.precision(.fractionLength(4)))
        switch mode {
        case .vectorOnly:
            let distance = (candidate.rawDistance ?? -candidate.score)
                .formatted(.number.precision(.fractionLength(4)))
            return String(localized: "distance \(distance)")
        case .textOnly:
            let bm25 = (candidate.rawDistance ?? -candidate.score)
                .formatted(.number.precision(.fractionLength(2)))
            return String(localized: "BM25 \(bm25)")
        case .hybrid:
            var parts = [String(localized: "score RRF \(score)")]
            if let rank = candidate.vectorRank { parts.append(String(localized: "v#\(rank)")) }
            if let rank = candidate.textRank { parts.append(String(localized: "t#\(rank)")) }
            return parts.joined(separator: " · ")
        case nil:
            return String(localized: "score \(score)")
        }
    }
}

#Preview {
    SearchScreen()
}
