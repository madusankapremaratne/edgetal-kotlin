/// Contract for the on-device generative model (Gemma-2B via MediaPipe).
abstract class LlmProvider {
  /// Whether the model file is present on disk.
  bool get isModelAvailable;

  /// Whether the real native LLM is loaded (vs. the offline mock).
  bool get isNativeActive;

  Future<bool> initialize();

  /// Generates a completion for [prompt]. Implementations should never throw
  /// for a missing model — callers gate on [isModelAvailable] first.
  Future<String> generateResponse(String prompt);
}
