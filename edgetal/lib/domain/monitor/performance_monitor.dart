import 'dart:io';

import '../../data/models/performance_metric.dart';
import '../../data/repository/resume_repository.dart';

/// Records latency / precision samples for the Benchmarks screen. Writes are
/// fire-and-forget so monitoring never blocks or breaks a user flow.
class PerformanceMonitor {
  PerformanceMonitor(this._repository);

  final ResumeRepository _repository;

  String get _manufacturer =>
      Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'Apple' : 'Desktop');
  String get _model => Platform.operatingSystemVersion;

  String get deviceInfo => '$_manufacturer · $_model';

  void recordLatency({
    required String type,
    required String name,
    required int durationMs,
    int resumeCount = 0,
    int embeddingCount = 0,
    double precision = 0,
    String contextData = '',
  }) {
    _save(PerformanceMetric(
      operationType: type,
      operationName: name,
      durationMs: durationMs,
      resumeCount: resumeCount,
      embeddingCount: embeddingCount,
      precision: precision,
      contextData: contextData,
      manufacturer: _manufacturer,
      model: _model,
    ));
  }

  void _save(PerformanceMetric metric) {
    // Intentionally not awaited.
    _repository.recordMetric(metric).catchError((_) {});
  }
}
