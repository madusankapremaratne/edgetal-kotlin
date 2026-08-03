import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/performance_metric.dart';
import '../../data/models/resource_sample.dart';
import '../../data/repository/resume_repository.dart';
import '../../domain/embedding/embedding_provider.dart';
import '../../domain/llm/candidate_agent.dart';
import '../../domain/llm/llm_provider.dart';
import '../../domain/monitor/performance_monitor.dart';
import '../../domain/monitor/resource_profiler.dart';
import '../../domain/search/vector_search_engine.dart';

/// Thermal status ordering — index used to find the worst status reached
/// during a profiling session and to decide the "throttled" flag.
const _thermalOrder = [
  'UNSUPPORTED',
  'NONE',
  'LIGHT',
  'MODERATE',
  'SEVERE',
  'CRITICAL',
  'EMERGENCY',
  'SHUTDOWN',
];

class ResourceProfileSummary {
  const ResourceProfileSummary({
    this.deviceInfo = '',
    this.llmBackend = 'CPU',
    this.completedQueries = 0,
    this.targetQueries = 0,
    this.failureCount = 0,
    this.elapsedMs = 0,
    this.peakMemMb = 0,
    this.avgMemMb = 0,
    this.batteryPctDrained = 0,
    this.batteryMahDrained = 0,
    this.avgCpuPct = 0,
    this.peakCpuPct = 0,
    this.maxThermalStatus = 'NONE',
    this.throttled = false,
    this.latencyDriftPct = 0,
  });

  final String deviceInfo;
  final String llmBackend;
  final int completedQueries;
  final int targetQueries;
  final int failureCount;
  final int elapsedMs;
  final double peakMemMb;
  final double avgMemMb;
  final double batteryPctDrained;
  final double batteryMahDrained;
  final double avgCpuPct;
  final double peakCpuPct;
  final String maxThermalStatus;
  final bool throttled;
  final double latencyDriftPct;

  bool get hasData => completedQueries > 0 || failureCount > 0;

  /// A short, paste-ready sentence for the paper's Results section.
  String get summaryText {
    if (!hasData) return '';
    final elapsed = Duration(milliseconds: elapsedMs);
    final mm = elapsed.inMinutes;
    final ss = elapsed.inSeconds.remainder(60);
    return 'Device: $deviceInfo · LLM backend: $llmBackend · '
        '$completedQueries/$targetQueries queries completed '
        '(${failureCount == 0 ? 'no failures' : '$failureCount failures'}) '
        'in ${mm}m ${ss}s. '
        'RAM: peak ${peakMemMb.toStringAsFixed(0)} MB, '
        'avg ${avgMemMb.toStringAsFixed(0)} MB. '
        'Battery: ${batteryPctDrained.toStringAsFixed(0)}% '
        '(${batteryMahDrained.toStringAsFixed(0)} mAh) drained. '
        'CPU: avg ${avgCpuPct.toStringAsFixed(0)}%, '
        'peak ${peakCpuPct.toStringAsFixed(0)}%. '
        'Thermal: max $maxThermalStatus'
        '${throttled ? ' (throttling observed)' : ' (no throttling observed)'}. '
        'Latency drift (first vs. last queries): '
        '${latencyDriftPct >= 0 ? '+' : ''}${latencyDriftPct.toStringAsFixed(1)}%.';
  }
}

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
    this.resourceSamples = const [],
    this.profileSummary = const ResourceProfileSummary(),
    this.profiling = false,
    this.profileProgress = (0, 0),
  });

  final List<PerformanceMetric> metrics;
  final BenchmarkSummary summary;
  final bool running;
  final List<ResourceSample> resourceSamples;
  final ResourceProfileSummary profileSummary;
  final bool profiling;
  final (int completed, int total) profileProgress;

  InsightsState copyWith({
    List<PerformanceMetric>? metrics,
    BenchmarkSummary? summary,
    bool? running,
    List<ResourceSample>? resourceSamples,
    ResourceProfileSummary? profileSummary,
    bool? profiling,
    (int, int)? profileProgress,
  }) =>
      InsightsState(
        metrics: metrics ?? this.metrics,
        summary: summary ?? this.summary,
        running: running ?? this.running,
        resourceSamples: resourceSamples ?? this.resourceSamples,
        profileSummary: profileSummary ?? this.profileSummary,
        profiling: profiling ?? this.profiling,
        profileProgress: profileProgress ?? this.profileProgress,
      );
}

class InsightsController extends StateNotifier<InsightsState> {
  InsightsController(
    this._repo,
    this._embedder,
    this._engine,
    this._monitor,
    this._candidateAgent,
    this._llm,
    this._resourceProfiler,
  ) : super(const InsightsState()) {
    load();
  }

  final ResumeRepository _repo;
  final EmbeddingProvider _embedder;
  final VectorSearchEngine _engine;
  final PerformanceMonitor _monitor;
  final CandidateAgent _candidateAgent;
  final LlmProvider _llm;
  final ResourceProfiler _resourceProfiler;

  /// Sampling cadence during a sustained-load profile. A single LLM
  /// generation can run many seconds to minutes, so this samples on a
  /// fixed wall-clock interval independent of query boundaries — sampling
  /// only at iteration edges would alias the CPU/thermal peak mid-generation.
  static const _sampleInterval = Duration(seconds: 2);

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
    final resourceSamples = await _repo.getAllResourceSamples();
    state = state.copyWith(
      metrics: metrics,
      summary: _summarise(metrics),
      resourceSamples: resourceSamples,
    );
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

  /// Runs the full on-device pipeline (embed → search → LLM candidate
  /// analysis) [totalQueries] times back-to-back, sampling memory / battery /
  /// CPU / thermal state on a fixed interval throughout, for the paper's
  /// computational resource analysis. Individual query failures are counted,
  /// not fatal — a sustained-load run should keep going and report what
  /// actually happened rather than abort on the first error.
  Future<void> runSustainedProfile({int totalQueries = 60}) async {
    if (state.profiling) return;
    state = state.copyWith(profiling: true, profileProgress: (0, totalQueries));

    await _embedder.initialize();
    final candidates = await _repo.getAllEmbeddings();
    await _resourceProfiler.reset();

    final samples = <ResourceSample>[];
    final latencies = <int>[];
    var failureCount = 0;
    var currentQueryIndex = -1;
    var samplingActive = true;
    final stopwatch = Stopwatch()..start();

    Future<void> samplingLoop() async {
      while (samplingActive) {
        final sample = await _resourceProfiler.sample(
          queryIndex: currentQueryIndex >= 0 ? currentQueryIndex : null,
          elapsedMs: stopwatch.elapsedMilliseconds,
          llmBackend: _llm.activeBackend,
        );
        if (sample != null) samples.add(sample);
        if (!samplingActive) return;
        await Future<void>.delayed(_sampleInterval);
      }
    }

    final samplingFuture = samplingLoop();

    try {
      for (var i = 0; i < totalQueries; i++) {
        currentQueryIndex = i;
        final query = _suite[i % _suite.length];
        final iterSw = Stopwatch()..start();
        try {
          final embedding = await _embedder.embedText(query);
          final results = await _engine.search(embedding, candidates, topK: 5);
          if (results.isNotEmpty) {
            final topResume = await _repo.getResume(results.first.resumeId);
            if (topResume != null) {
              var failed = false;
              await for (final step
                  in _candidateAgent.evaluateCandidate(topResume, query)) {
                if (step is AgentError) failed = true;
              }
              if (failed) failureCount++;
            }
          }
          iterSw.stop();
          latencies.add(iterSw.elapsedMilliseconds);
        } catch (_) {
          failureCount++;
        }
        state = state.copyWith(profileProgress: (i + 1, totalQueries));
      }
    } finally {
      samplingActive = false;
      currentQueryIndex = -1;
      await samplingFuture;
    }
    stopwatch.stop();

    final finalSample = await _resourceProfiler.sample(
      elapsedMs: stopwatch.elapsedMilliseconds,
      llmBackend: _llm.activeBackend,
    );
    if (finalSample != null) samples.add(finalSample);

    for (final sample in samples) {
      await _repo.recordResourceSample(sample);
    }

    final summary = _summariseResources(
      samples,
      latencies,
      failureCount: failureCount,
      targetQueries: totalQueries,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
    final storedSamples = await _repo.getAllResourceSamples();
    state = state.copyWith(
      profiling: false,
      resourceSamples: storedSamples,
      profileSummary: summary,
    );
  }

  Future<void> clearResourceSamples() async {
    await _repo.clearResourceSamples();
    state = state.copyWith(
      resourceSamples: const [],
      profileSummary: const ResourceProfileSummary(),
    );
  }

  String exportResourceCsv() {
    final buffer = StringBuffer(
        'elapsed_ms,query_index,mem_pss_mb,mem_avail_mb,battery_pct,'
        'battery_current_ma,battery_charge_counter_mah,charging,cpu_app_pct,'
        'thermal_status,llm_backend,manufacturer,model,timestamp\n');
    for (final s in state.resourceSamples) {
      buffer.writeln(
          '${s.elapsedMs},${s.queryIndex ?? ''},${s.memPssMb.toStringAsFixed(1)},'
          '${s.memAvailMb.toStringAsFixed(1)},${s.batteryPct},'
          '${s.batteryCurrentMa.toStringAsFixed(1)},'
          '${s.batteryChargeCounterMah.toStringAsFixed(1)},${s.charging},'
          '${s.cpuAppPct.toStringAsFixed(1)},${s.thermalStatus},${s.llmBackend},'
          '"${s.manufacturer}","${s.model}",${s.timestamp}');
    }
    return buffer.toString();
  }

  ResourceProfileSummary _summariseResources(
    List<ResourceSample> samples,
    List<int> latencies, {
    required int failureCount,
    required int targetQueries,
    required int elapsedMs,
  }) {
    if (samples.isEmpty) {
      return ResourceProfileSummary(
        llmBackend: _llm.activeBackend,
        completedQueries: latencies.length,
        targetQueries: targetQueries,
        failureCount: failureCount,
        elapsedMs: elapsedMs,
      );
    }

    final memValues = samples.map((s) => s.memPssMb).toList();
    final cpuValues = samples.map((s) => s.cpuAppPct).toList();
    final first = samples.first;
    final last = samples.last;

    var maxThermalIdx = 0;
    for (final s in samples) {
      final idx = _thermalOrder.indexOf(s.thermalStatus);
      if (idx > maxThermalIdx) maxThermalIdx = idx;
    }
    final maxThermal = _thermalOrder[maxThermalIdx];
    final throttled = maxThermalIdx >= _thermalOrder.indexOf('MODERATE');

    double latencyDrift = 0;
    if (latencies.length >= 4) {
      final n = (latencies.length ~/ 2).clamp(1, 10);
      final firstAvg = latencies.take(n).reduce((a, b) => a + b) / n;
      final lastAvg =
          latencies.skip(latencies.length - n).reduce((a, b) => a + b) / n;
      if (firstAvg > 0) latencyDrift = (lastAvg - firstAvg) / firstAvg * 100;
    }

    return ResourceProfileSummary(
      deviceInfo: '${first.manufacturer} ${first.model}'.trim(),
      llmBackend: last.llmBackend,
      completedQueries: latencies.length,
      targetQueries: targetQueries,
      failureCount: failureCount,
      elapsedMs: elapsedMs,
      peakMemMb: memValues.reduce(math.max),
      avgMemMb: memValues.reduce((a, b) => a + b) / memValues.length,
      batteryPctDrained: (first.batteryPct - last.batteryPct).toDouble(),
      batteryMahDrained:
          first.batteryChargeCounterMah - last.batteryChargeCounterMah,
      avgCpuPct: cpuValues.reduce((a, b) => a + b) / cpuValues.length,
      peakCpuPct: cpuValues.reduce(math.max),
      maxThermalStatus: maxThermal,
      throttled: throttled,
      latencyDriftPct: latencyDrift,
    );
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
    ref.watch(candidateAgentProvider),
    ref.watch(llmProviderProvider),
    ref.watch(resourceProfilerProvider),
  );
});
