package com.knovik.edgetal

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native side of the `edgetal/llm` channel — on-device generative inference
 * (Gemma-2B via MediaPipe LLM Inference), mirroring EdgeTal's
 * `LlmInferenceProvider`.
 *
 * The Dart `ModelDownloadManager` downloads the model into the app's support
 * directory (`context.filesDir`/.. — `getApplicationSupportDirectory`). To
 * activate:
 *   1. Add: implementation("com.google.mediapipe:tasks-genai:0.10.21")
 *   2. Implement the TODOs below using `LlmInference` / `LlmInferenceSession`.
 *
 * Until then the Dart `NativeLlmProvider` falls back to its offline heuristic,
 * and the UI badges every result accordingly.
 */
class LlmChannel(private val context: Context) {

    // private var inference: LlmInference? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "edgetal/llm").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val fileName = call.argument<String>("modelFileName")
                        ?: "gemma-2b-it-cpu-int4.bin"
                    val modelFile = File(modelDir(), fileName)
                    if (!modelFile.exists()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    // TODO: create LlmInference from modelFile.absolutePath, e.g.
                    //
                    // val options = LlmInference.LlmInferenceOptions.builder()
                    //     .setModelPath(modelFile.absolutePath)
                    //     .setMaxTokens(512)
                    //     .build()
                    // inference = LlmInference.createFromOptions(context, options)
                    // result.success(true)
                    result.success(false)
                }
                "generate" -> {
                    // val prompt = call.argument<String>("prompt") ?: ""
                    // result.success(inference?.generateResponse(prompt))
                    result.error("UNIMPLEMENTED", "MediaPipe LLM not wired yet", null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Matches Dart's `getApplicationSupportDirectory()` location used by
     * `ModelDownloadManager` to store the downloaded model.
     */
    private fun modelDir(): File = File(context.filesDir.parentFile, "files")
        .takeIf { it.exists() } ?: context.filesDir
}
