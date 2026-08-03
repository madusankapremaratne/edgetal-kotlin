/// Contract for the on-device generative model (Gemma-2B via MediaPipe).
abstract class LlmProvider {
  /// Whether the model file is present on disk.
  bool get isModelAvailable;

  /// Whether the real native LLM is loaded (vs. the offline mock).
  bool get isNativeActive;

  /// The inference backend actually driving generation — "CPU" or "GPU".
  /// Reported by the native layer, since a requested GPU delegate can
  /// silently fall back to CPU on unsupported hardware.
  String get activeBackend;

  Future<bool> initialize();

  /// Switches the preferred inference backend ("CPU"/"GPU") and forces a
  /// live re-initialization so the change takes effect immediately.
  Future<void> setBackend(String backend);

  /// Generates a completion for [prompt]. Implementations should never throw
  /// for a missing model — callers gate on [isModelAvailable] first.
  Future<String> generateResponse(String prompt);
}
