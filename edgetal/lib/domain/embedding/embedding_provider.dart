import 'dart:math' as math;

/// Contract for turning text into a fixed-size vector, entirely on-device.
///
/// The production implementation bridges to MediaPipe's Text Embedder over a
/// platform channel; a deterministic offline fallback keeps the app usable in
/// development and on platforms where the native layer isn't wired yet.
abstract class EmbeddingProvider {
  int get dimension;

  /// Human-readable backend name, surfaced in the Models screen.
  String get backendLabel;

  /// Whether the real on-device model is active (vs. the offline fallback).
  bool get isNativeActive;

  Future<void> initialize();

  /// Returns a unit-normalised embedding for [text].
  Future<List<double>> embedText(String text);

  /// Splits a long section into chunks that fit the model's context, returning
  /// `(text, segmentType)` pairs. Mirrors the original segmentation logic.
  List<({String text, String segmentType})> segmentText(
    String text,
    String segmentType, {
    int maxSegmentLength = 512,
  }) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length <= maxSegmentLength) {
      return [(text: cleaned, segmentType: segmentType)];
    }

    final sentences = cleaned.split(RegExp(r'[.!?]'));
    final segments = <String>[];
    final current = StringBuffer();

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      final withPunct = '$trimmed.';
      final newLength = current.length + withPunct.length;
      if (newLength > maxSegmentLength && current.isNotEmpty) {
        segments.add(current.toString());
        current.clear();
        current.write(withPunct);
      } else {
        if (current.isNotEmpty) current.write(' ');
        current.write(withPunct);
      }
    }
    if (current.isNotEmpty) segments.add(current.toString());

    return segments.map((s) => (text: s, segmentType: segmentType)).toList();
  }

  static List<double> normalize(List<double> v) {
    var magnitude = 0.0;
    for (final x in v) {
      magnitude += x * x;
    }
    magnitude = math.sqrt(magnitude);
    if (magnitude == 0) return v;
    return [for (final x in v) x / magnitude];
  }
}
