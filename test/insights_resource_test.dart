import 'package:flutter_test/flutter_test.dart';

import 'package:edgetal/data/local/local_database.dart';
import 'package:edgetal/data/models/resource_sample.dart';
import 'package:edgetal/data/repository/resume_repository.dart';
import 'package:edgetal/domain/embedding/hashing_embedding_provider.dart';
import 'package:edgetal/domain/llm/candidate_agent.dart';
import 'package:edgetal/domain/llm/mock_llm_provider.dart';
import 'package:edgetal/domain/monitor/performance_monitor.dart';
import 'package:edgetal/domain/monitor/resource_profiler.dart';
import 'package:edgetal/domain/search/vector_search_engine.dart';
import 'package:edgetal/features/insights/insights_controller.dart';

class _NoopMonitor implements PerformanceMonitor {
  @override
  String get deviceInfo => 'test';
  @override
  void recordLatency({
    required String type,
    required String name,
    required int durationMs,
    int resumeCount = 0,
    int embeddingCount = 0,
    double precision = 0,
    String contextData = '',
  }) {}
  @override
  noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('exportResourceCsv formats stored resource samples', () async {
    final db = LocalDatabase.instance;
    db.resourceSamples.clear();
    db.resourceSamples.add(ResourceSample(
      id: 1,
      elapsedMs: 2000,
      queryIndex: 0,
      memPssMb: 512.3,
      memAvailMb: 1024,
      memTotalMb: 4096,
      batteryPct: 80,
      batteryCurrentMa: -350.5,
      batteryChargeCounterMah: 2500,
      charging: false,
      cpuAppPct: 42.1,
      thermalStatus: 'LIGHT',
      llmBackend: 'CPU',
      manufacturer: 'Google',
      model: 'Pixel 7 Pro',
      timestamp: 1000,
    ));

    final monitor = _NoopMonitor();
    final controller = InsightsController(
      ResumeRepository(db),
      HashingEmbeddingProvider(),
      VectorSearchEngine(monitor),
      monitor,
      CandidateAgent(MockLlmProvider(), monitor),
      MockLlmProvider(),
      ResourceProfiler(),
    );
    await controller.load();

    final csv = controller.exportResourceCsv();
    expect(csv, contains('elapsed_ms,query_index,mem_pss_mb'));
    expect(csv, contains('2000,0,512.3'));
    expect(csv, contains('"Google","Pixel 7 Pro"'));

    db.resourceSamples.clear();
  });

  test('ResourceProfileSummary.summaryText reports throttling and drift', () {
    const summary = ResourceProfileSummary(
      deviceInfo: 'Xiaomi Redmi Note 7',
      llmBackend: 'CPU',
      completedQueries: 58,
      targetQueries: 60,
      failureCount: 2,
      elapsedMs: 754000,
      peakMemMb: 611,
      avgMemMb: 540,
      batteryPctDrained: 7,
      batteryMahDrained: 245,
      avgCpuPct: 38,
      peakCpuPct: 92,
      maxThermalStatus: 'SEVERE',
      throttled: true,
      latencyDriftPct: 18.4,
    );

    expect(summary.hasData, isTrue);
    final text = summary.summaryText;
    expect(text, contains('58/60 queries completed'));
    expect(text, contains('2 failures'));
    expect(text, contains('throttling observed'));
    expect(text, contains('+18.4%'));
  });

  test('ResourceProfileSummary.hasData is false with no queries and no failures', () {
    const summary = ResourceProfileSummary();
    expect(summary.hasData, isFalse);
    expect(summary.summaryText, isEmpty);
  });
}
