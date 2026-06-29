import 'dart:math' as math;

import 'embedding_provider.dart';

/// Deterministic, dependency-free embedder used as the offline fallback.
///
/// It hashes each token into a fixed number of buckets with sub-linear term
/// weighting, then unit-normalises. It is **not** semantic — it captures
/// lexical overlap only — but it makes the entire search / ranking / agentic UI
/// fully exercisable without the native MediaPipe model, and texts that share
/// vocabulary do score higher, which is enough for realistic demos and tests.
class HashingEmbeddingProvider extends EmbeddingProvider {
  HashingEmbeddingProvider({this.dimension = 512});

  @override
  final int dimension;

  @override
  String get backendLabel => 'Offline hashing embedder (development)';

  @override
  bool get isNativeActive => false;

  @override
  Future<void> initialize() async {}

  static final RegExp _token = RegExp(r'[a-z0-9]+');

  @override
  Future<List<double>> embedText(String text) async {
    final vec = List<double>.filled(dimension, 0);
    final counts = <int, double>{};

    for (final match in _token.allMatches(text.toLowerCase())) {
      final tok = match.group(0)!;
      if (tok.length < 2) continue;
      final bucket = _hash(tok) % dimension;
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }

    counts.forEach((bucket, count) {
      // 1 + ln(count): classic dampened term-frequency weighting.
      vec[bucket] = 1 + math.log(count);
    });

    return EmbeddingProvider.normalize(vec);
  }

  int _hash(String s) {
    // FNV-1a, kept positive.
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }
}
