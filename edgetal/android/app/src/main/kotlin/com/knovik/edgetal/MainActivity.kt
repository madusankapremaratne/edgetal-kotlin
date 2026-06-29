package com.knovik.edgetal

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Registers the on-device ML platform channels that back EdgeTal's Dart
 * NativeEmbeddingProvider / NativeLlmProvider.
 *
 * Both channels are optional: if the handlers throw or are absent, the Dart
 * side transparently falls back to the offline embedder / heuristic LLM, so the
 * app always runs. Fill in the MediaPipe calls (see the TODOs in
 * EmbedderChannel.kt and LlmChannel.kt) to enable the true on-device pipeline
 * the original EdgeTal app shipped.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EmbedderChannel(applicationContext).register(messenger)
        LlmChannel(applicationContext).register(messenger)
    }
}
