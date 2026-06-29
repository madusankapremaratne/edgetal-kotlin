import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'llm_provider.dart';
import 'mock_llm_provider.dart';
import 'model_download_manager.dart';

/// Bridges to MediaPipe's LLM Inference (Gemma-2B) on the native side via the
/// `edgetal/llm` [MethodChannel]. When the native layer or the model file isn't
/// present, it falls back to [MockLlmProvider] so the agentic search and
/// analysis flows stay demonstrable — every response is badged in the UI as
/// "on-device model" vs. "offline heuristic".
class NativeLlmProvider implements LlmProvider {
  NativeLlmProvider(this._downloads, {LlmProvider? fallback})
      : _fallback = fallback ?? MockLlmProvider();

  static const _channel = MethodChannel('edgetal/llm');

  final ModelDownloadManager _downloads;
  final LlmProvider _fallback;
  bool _nativeReady = false;

  @override
  bool get isNativeActive => _nativeReady;

  /// True when there is *some* usable generative backend (native model or the
  /// offline heuristic). The UI distinguishes the two via [isNativeActive].
  @override
  bool get isModelAvailable => true;

  @override
  Future<bool> initialize() async {
    if (_nativeReady) return true;
    if (!await _downloads.isModelInstalled()) {
      _nativeReady = false;
      return true; // fallback will serve requests
    }
    try {
      final ok = await _channel.invokeMethod<bool>('initialize', {
        'modelPath': await _downloads.modelFilePath(),
      });
      _nativeReady = ok ?? false;
    } on MissingPluginException {
      _nativeReady = false;
    } on PlatformException catch (e) {
      debugPrint('Native LLM init failed: ${e.message}');
      _nativeReady = false;
    }
    return true;
  }

  @override
  Future<String> generateResponse(String prompt) async {
    await initialize();
    if (!_nativeReady) return _fallback.generateResponse(prompt);
    try {
      final result = await _channel
          .invokeMethod<String>('generate', {'prompt': prompt});
      return result ?? _fallback.generateResponse(prompt);
    } on PlatformException catch (e) {
      debugPrint('Native LLM generate failed: ${e.message}');
      return _fallback.generateResponse(prompt);
    }
  }
}
