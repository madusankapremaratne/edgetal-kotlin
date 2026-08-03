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
 *
 * `initialize` accepts an optional `backend` ("CPU"/"GPU", default CPU) for
 * the resource-analysis GPU-delegate comparison. GPU is attempted via
 * [LlmInference.Backend.GPU]; if MediaPipe rejects it on the target device,
 * the session falls back to CPU and the *actual* backend that loaded is
 * reported back in the result — never assume the request was honoured.
 */
class LlmChannel(private val context: Context) {

    private var inference: LlmInference? = null
    private var activeBackend: String = "CPU"
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "edgetal/llm").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelPath = call.argument<String>("modelPath")
                    val requestedBackend = call.argument<String>("backend") ?: "CPU"
                    executor.execute {
                        try {
                            if (modelPath == null || !File(modelPath).exists()) {
                                main.post {
                                    result.success(mapOf("ready" to false, "backend" to activeBackend))
                                }
                                return@execute
                            }
                            if (inference == null || activeBackend != requestedBackend) {
                                inference?.close()
                                inference = null
                                activeBackend = buildInference(modelPath, requestedBackend)
                            }
                            main.post {
                                result.success(mapOf("ready" to true, "backend" to activeBackend))
                            }
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

    /**
     * Builds [inference] for the requested backend, returning whichever
     * backend actually ended up loaded. GPU delegation can throw on devices/
     * ops MediaPipe doesn't support (e.g. the Redmi Note 7's Snapdragon 660
     * has no comparable GPU delegate path) — that failure is caught here and
     * silently retried on CPU rather than surfaced as an init error, since
     * CPU-only is always a valid outcome to report in the resource analysis.
     */
    private fun buildInference(modelPath: String, requestedBackend: String): String {
        if (requestedBackend == "GPU") {
            try {
                val gpuOptions = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(modelPath)
                    .setMaxTokens(512)
                    .setPreferredBackend(LlmInference.Backend.GPU)
                    .build()
                inference = LlmInference.createFromOptions(context, gpuOptions)
                return "GPU"
            } catch (e: Exception) {
                inference = null
            }
        }
        val cpuOptions = LlmInference.LlmInferenceOptions.builder()
            .setModelPath(modelPath)
            .setMaxTokens(512)
            .setPreferredBackend(LlmInference.Backend.CPU)
            .build()
        inference = LlmInference.createFromOptions(context, cpuOptions)
        return "CPU"
    }
}
