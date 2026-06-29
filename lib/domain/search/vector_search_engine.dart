import 'dart:math' as math;

import '../../data/models/resume_embedding.dart';
import '../monitor/performance_monitor.dart';

/// A ranked match returned by [VectorSearchEngine].
class SearchResult {
  SearchResult({
    required this.embedding,
    required this.similarityScore,
    required this.resumeId,
    required this.segmentType,
    required this.segmentText,
  });

  final ResumeEmbedding embedding;
  final double similarityScore; // 0..1
  final int resumeId;
  final String segmentType;
  final String segmentText;
}

/// On-device retrieval (the "Decide" phase). Brute-force cosine similarity over
/// the locally stored embeddings — fast enough for the demo dataset and trivial
/// to swap for ObjectBox's HNSW index later.
class VectorSearchEngine {
  VectorSearchEngine(this._monitor);

  final PerformanceMonitor _monitor;

  Future<List<SearchResult>> search(
    List<double> queryEmbedding,
    List<ResumeEmbedding> candidates, {
    int topK = 10,
    double similarityThreshold = 0.3,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (candidates.isEmpty) return [];
    if (queryEmbedding.length != candidates.first.embedding.length) {
      return [];
    }

    final results = <SearchResult>[];
    for (final e in candidates) {
      final score = _cosine(queryEmbedding, e.embedding);
      if (score >= similarityThreshold) {
        results.add(SearchResult(
          embedding: e,
          similarityScore: score,
          resumeId: e.resumeId,
          segmentType: e.segmentType,
          segmentText: e.segmentText,
        ));
      }
    }
    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    final top = results.take(topK).toList();

    stopwatch.stop();
    _monitor.recordLatency(
      type: 'retrieval',
      name: 'Vector Search',
      durationMs: stopwatch.elapsedMilliseconds,
      embeddingCount: candidates.length,
    );
    return top;
  }

  Future<List<SearchResult>> searchBySegmentType(
    List<double> queryEmbedding,
    List<ResumeEmbedding> candidates,
    String segmentType, {
    int topK = 10,
    double similarityThreshold = 0.3,
  }) async {
    final filtered =
        candidates.where((c) => c.segmentType == segmentType).toList();
    return search(queryEmbedding, filtered,
        topK: topK, similarityThreshold: similarityThreshold);
  }

  double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    var dot = 0.0, normA = 0.0, normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    final sim = dot / (math.sqrt(normA) * math.sqrt(normB));
    return sim.clamp(-1.0, 1.0);
  }
}
