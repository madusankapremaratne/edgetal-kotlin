package com.knovik.edgetal

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Native side of the `edgetal/llm` channel — on-device generative inference
 * (Gemma-2B via MediaPipe LLM Inference). Ported from the original EdgeTal
 * `LlmInferenceProvider`.
 *
 * The Dart `ModelDownloadManager` downloads the model and passes its absolute
 * path to `initialize` (so the two sides never disagree about the location).
 * A fresh session per `generate` keeps prompts independent (no context bleed
 * between the search-reformulation and candidate-analysis agents).
 */
class LlmChannel(private val context: Context) {

    private var inference: LlmInference? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "edgetal/llm").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelPath = call.argument<String>("modelPath")
                    executor.execute {
                        try {
                            if (modelPath == null || !File(modelPath).exists()) {
                                main.post { result.success(false) }
                                return@execute
                            }
                            if (inference == null) {
                                val options = LlmInference.LlmInferenceOptions.builder()
                                    .setModelPath(modelPath)
                                    .setMaxTokens(512)
                                    .build()
                                inference = LlmInference.createFromOptions(context, options)
                            }
                            main.post { result.success(true) }
                        } catch (e: Exception) {
                            main.post { result.error("LLM_INIT_FAILED", e.message, null) }
                        }
                    }
                }
                "generate" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    executor.execute {
                        try {
                            val inf = inference
                                ?: throw IllegalStateException("LLM not initialized")
                            val sessionOptions =
                                LlmInferenceSession.LlmInferenceSessionOptions.builder()
                                    .setTemperature(0.7f)
                                    .setRandomSeed(42)
                                    .build()
                            val response = LlmInferenceSession
                                .createFromOptions(inf, sessionOptions).use { session ->
                                    session.addQueryChunk(prompt)
                                    session.generateResponse()
                                }
                            main.post { result.success(response) }
                        } catch (e: Exception) {
                            main.post { result.error("LLM_GEN_FAILED", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
