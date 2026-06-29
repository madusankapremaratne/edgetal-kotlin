import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'embedding_provider.dart';
import 'hashing_embedding_provider.dart';

/// Bridges to MediaPipe's Text Embedder on the native side.
///
/// The Android/iOS host implements the `edgetal/embedder` [MethodChannel] with
/// `initialize` and `embed` handlers (see `android/.../EmbedderChannel.kt`).
/// Until that's present — or on unsupported platforms — every call transparently
/// falls back to [HashingEmbeddingProvider] so the UI never breaks.
class NativeEmbeddingProvider extends EmbeddingProvider {
  NativeEmbeddingProvider({EmbeddingProvider? fallback})
      : _fallback = fallback ?? HashingEmbeddingProvider();

  static const _channel = MethodChannel('edgetal/embedder');

  final EmbeddingProvider _fallback;
  bool _nativeReady = false;
  int _dimension = 512;

  @override
  int get dimension => _nativeReady ? _dimension : _fallback.dimension;

  @override
  bool get isNativeActive => _nativeReady;

  @override
  String get backendLabel => _nativeReady
      ? 'MediaPipe Text Embedder (on-device)'
      : _fallback.backendLabel;

  @override
  Future<void> initialize() async {
    await _fallback.initialize();
    try {
      final dim = await _channel.invokeMethod<int>('initialize');
      if (dim != null && dim > 0) _dimension = dim;
      _nativeReady = true;
    } on MissingPluginException {
      _nativeReady = false; // Native layer not wired — use fallback silently.
    } on PlatformException catch (e) {
      debugPrint('Native embedder unavailable: ${e.message}');
      _nativeReady = false;
    }
  }

  @override
  Future<List<double>> embedText(String text) async {
    if (!_nativeReady) return _fallback.embedText(text);
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('embed', {'text': text});
      if (result == null) return _fallback.embedText(text);
      final vec = result.map((e) => (e as num).toDouble()).toList();
      return EmbeddingProvider.normalize(vec);
    } on PlatformException catch (e) {
      debugPrint('Native embed failed, using fallback: ${e.message}');
      return _fallback.embedText(text);
    }
  }
}
