import Foundation

/// Post-embedding vector transform, recorded in the manifest
/// (`transformIdentifier`/`transformVersion`) so that enabling, disabling or
/// changing it invalidates existing indexes like any other semantic mismatch.
public enum VectorTransformKind: String, Sendable, CaseIterable, Equatable {
    /// Vectors are used exactly as the provider produced them (0.1.0 behavior).
    case identity
    /// Corpus mean-centering: the centroid of all indexed chunk vectors is
    /// subtracted from every indexed and query vector, which is then
    /// re-L2-normalized. Counters the anisotropy of mean-pooled contextual
    /// embeddings — raw cosine similarities compress into a narrow high band
    /// and lose discriminative power, especially on homogeneous corpora.
    ///
    /// The centroid is computed on the first full indexing pass and frozen for
    /// the lifetime of the index: incremental syncs reuse it, and a full
    /// rebuild (or any manifest invalidation) recomputes it.
    case meanCentering

    var identifier: String {
        switch self {
        case .identity: "identity"
        case .meanCentering: "mean-center"
        }
    }

    var version: String { "v1" }
}

/// Math for the mean-centering transform. Pure functions, no state.
enum VectorTransform {

    /// Component-wise mean of the given vectors. Nil for an empty input.
    static func centroid(of vectors: [[Float]]) -> [Float]? {
        guard let first = vectors.first else { return nil }
        var sum = [Double](repeating: 0, count: first.count)
        for vector in vectors {
            for i in 0..<sum.count {
                sum[i] += Double(vector[i])
            }
        }
        let divisor = Double(vectors.count)
        return sum.map { Float($0 / divisor) }
    }

    /// Subtracts the centroid and re-L2-normalizes. Falls back to the raw
    /// vector when the difference is (numerically) zero — a vector identical
    /// to the centroid has no direction left to normalize.
    static func meanCenter(_ vector: [Float], centroid: [Float]) -> [Float] {
        guard vector.count == centroid.count else { return vector }
        var centered = [Double](repeating: 0, count: vector.count)
        var normSquared = 0.0
        for i in 0..<vector.count {
            let value = Double(vector[i]) - Double(centroid[i])
            centered[i] = value
            normSquared += value * value
        }
        let norm = normSquared.squareRoot()
        guard norm > .ulpOfOne else { return vector }
        return centered.map { Float($0 / norm) }
    }
}
