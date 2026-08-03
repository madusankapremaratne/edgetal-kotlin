import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/resource_sample.dart';

/// Bridges to the `edgetal/resource_monitor` native channel — memory /
/// battery / CPU / thermal snapshots for the sustained-load resource
/// profiler. On platforms without the channel (iOS/macOS stubs, desktop),
/// [sample] returns null and the caller degrades gracefully, mirroring
/// [NativeEmbeddingProvider]/[NativeLlmProvider]'s fallback shape.
class ResourceProfiler {
  static const _channel = MethodChannel('edgetal/resource_monitor');

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Clears the native CPU-delta baseline so a fresh profiling session
  /// doesn't inherit stale timing from a previous run.
  Future<void> reset() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('reset');
    } on MissingPluginException {
      // Native layer not wired — nothing to reset.
    } on PlatformException catch (e) {
      debugPrint('Resource monitor reset failed: ${e.message}');
    }
  }

  Future<ResourceSample?> sample({
    int? queryIndex,
    required int elapsedMs,
    String llmBackend = 'CPU',
  }) async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('sample');
      if (raw == null) return null;
      return ResourceSample(
        elapsedMs: elapsedMs,
        queryIndex: queryIndex,
        memPssMb: (raw['memPssMb'] as num?)?.toDouble() ?? 0,
        memAvailMb: (raw['memAvailMb'] as num?)?.toDouble() ?? 0,
        memTotalMb: (raw['memTotalMb'] as num?)?.toDouble() ?? 0,
        batteryPct: raw['batteryPct'] as int? ?? 0,
        batteryCurrentMa: ((raw['batteryCurrentUa'] as num?)?.toDouble() ?? 0) / 1000.0,
        batteryChargeCounterMah:
            ((raw['batteryChargeCounterUah'] as num?)?.toDouble() ?? 0) / 1000.0,
        charging: raw['charging'] as bool? ?? false,
        cpuAppPct: (raw['cpuAppPct'] as num?)?.toDouble() ?? 0,
        thermalStatus: raw['thermalStatus'] as String? ?? 'UNKNOWN',
        llmBackend: llmBackend,
        manufacturer: raw['manufacturer'] as String? ?? '',
        model: raw['model'] as String? ?? '',
      );
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('Resource sample failed: ${e.message}');
      return null;
    }
  }
}
