import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/performance_metric.dart';
import '../../data/repository/resume_repository.dart';
import '../../domain/embedding/embedding_provider.dart';
import '../../domain/monitor/performance_monitor.dart';
import '../../domain/search/vector_search_engine.dart';

class BenchmarkSummary {
  const BenchmarkSummary({
    this.deviceInfo = '',
    this.avgIngestionMs = 0,
    this.avgRetrievalMs = 0,
    this.avgAgenticMs = 0,
    this.meanPrecision = 0,
  });

  final String deviceInfo;
  final double avgIngestionMs;
  final double avgRetrievalMs;
  final double avgAgenticMs;
  final double meanPrecision;
}

class InsightsState {
  const InsightsState({
    this.metrics = const [],
    this.summary = const BenchmarkSummary(),
    this.running = false,
  });

  final List<PerformanceMetric> metrics;
  final BenchmarkSummary summary;
  final bool running;

  InsightsState copyWith({
    List<PerformanceMetric>? metrics,
    BenchmarkSummary? summary,
    bool? running,
  }) =>
      InsightsState(
        metrics: metrics ?? this.metrics,
        summary: summary ?? this.summary,
        running: running ?? this.running,
      );
}

class InsightsController extends StateNotifier<InsightsState> {
  InsightsController(this._repo, this._embedder, this._engine, this._monitor)
      : super(const InsightsState()) {
    load();
  }

  final ResumeRepository _repo;
  final EmbeddingProvider _embedder;
  final VectorSearchEngine _engine;
  final PerformanceMonitor _monitor;

  static const _suite = [
    'experienced backend engineer with cloud skills',
    'product designer focused on accessibility',
    'machine learning engineer with NLP background',
    'engineering manager who leads delivery teams',
    'frontend developer with strong typescript',
    'devops platform engineer kubernetes terraform',
    'talent acquisition recruiter sourcing',
    'full stack engineer node react',
  ];

  Future<void> load() async {
    final metrics = await _repo.getAllPerformanceMetrics();
    state = state.copyWith(metrics: metrics, summary: _summarise(metrics));
  }

  Future<void> runAutoBenchmark() async {
    state = state.copyWith(running: true);
    await _embedder.initialize();
    final candidates = await _repo.getAllEmbeddings();
    for (final query in _suite) {
      final sw = Stopwatch()..start();
      final embedding = await _embedder.embedText(query);
      final results = await _engine.search(embedding, candidates, topK: 5);
      sw.stop();
      // Precision proxy: share of top-5 above a confident similarity threshold.
      final precision = results.isEmpty
          ? 0.0
          : results.where((r) => r.similarityScore >= 0.5).length /
              results.length;
      _monitor.recordLatency(
        type: 'agentic_search',
        name: 'Suite: "${_short(query)}"',
        durationMs: sw.elapsedMilliseconds,
        embeddingCount: candidates.length,
        precision: precision,
        contextData: query,
      );
    }
    await load();
    state = state.copyWith(running: false);
  }

  Future<void> clear() async {
    await _repo.clearPerformanceMetrics();
    await load();
  }

  String exportCsv() {
    final buffer = StringBuffer(
        'type,operation,duration_ms,precision,resumes,embeddings,timestamp\n');
    for (final m in state.metrics) {
      buffer.writeln('${m.operationType},"${m.operationName}",${m.durationMs},'
          '${m.precision.toStringAsFixed(3)},${m.resumeCount},'
          '${m.embeddingCount},${m.timestamp}');
    }
    return buffer.toString();
  }

  BenchmarkSummary _summarise(List<PerformanceMetric> metrics) {
    double avg(bool Function(PerformanceMetric) test) {
      final filtered = metrics.where(test).toList();
      if (filtered.isEmpty) return 0;
      return filtered.map((m) => m.durationMs).reduce((a, b) => a + b) /
          filtered.length;
    }

    final withPrecision = metrics.where((m) => m.precision > 0).toList();
    final meanPrecision = withPrecision.isEmpty
        ? 0.0
        : withPrecision.map((m) => m.precision).reduce((a, b) => a + b) /
            withPrecision.length;

    return BenchmarkSummary(
      deviceInfo: _monitor.deviceInfo,
      avgIngestionMs: avg((m) => m.operationType == 'ingestion'),
      avgRetrievalMs: avg((m) => m.operationType == 'retrieval'),
      avgAgenticMs: avg((m) =>
          m.operationType == 'agentic_search' ||
          m.operationType == 'agentic_reasoning'),
      meanPrecision: meanPrecision,
    );
  }

  String _short(String s) => s.length <= 28 ? s : '${s.substring(0, 28)}…';
}

final insightsControllerProvider =
    StateNotifierProvider<InsightsController, InsightsState>((ref) {
  return InsightsController(
    ref.watch(resumeRepositoryProvider),
    ref.watch(embeddingProviderProvider),
    ref.watch(vectorSearchEngineProvider),
    ref.watch(performanceMonitorProvider),
  );
});
