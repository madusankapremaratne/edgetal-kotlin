package com.knovik.edgetal

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.text.textembedder.TextEmbedder
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import kotlin.math.sqrt

/**
 * Native side of the `edgetal/embedder` channel — on-device text embeddings via
 * MediaPipe's Text Embedder.
 */
class EmbedderChannel(private val context: Context) {

    private var embedder: TextEmbedder? = null
    private var dimension: Int = 0
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "edgetal/embedder").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> executor.execute {
                    try {
                        val dim = ensureEmbedder()
                        Log.i("EmbedderChannel", "Initialization succeeded with dimension $dim")
                        main.post { result.success(dim) }
                    } catch (e: Exception) {
                        Log.e("EmbedderChannel", "Initialization failed", e)
                        main.post {
                            result.error(
                                "INIT_FAILED",
                                "${e.javaClass.simpleName}: ${e.message}",
                                e.stackTraceToString()
                            )
                        }
                    }
                }
                "embed" -> {
                    val text = call.argument<String>("text") ?: ""
                    executor.execute {
                        try {
                            ensureEmbedder()
                            val raw = embedder!!.embed(text)
                                .embeddingResult()
                                .embeddings()
                                .first()
                                .floatEmbedding()
                            val normalized = normalize(raw).map { it.toDouble() }
                            main.post { result.success(normalized) }
                        } catch (e: Exception) {
                            Log.e("EmbedderChannel", "Embedding failed for text length ${text.length}", e)
                            main.post { result.error("EMBED_FAILED", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Lazily builds the embedder and returns its output dimension. */
    @Synchronized
    private fun ensureEmbedder(): Int {
        if (embedder == null) {
            val options = TextEmbedder.TextEmbedderOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("text_embedder.tflite")
                        .build()
                )
                .build()
            embedder = TextEmbedder.createFromOptions(context, options)
            val probe = embedder!!.embed("dimension probe")
            dimension = probe.embeddingResult()
                .embeddings()
                .first()
                .floatEmbedding()
                .size
            Log.i("EmbedderChannel", "MediaPipe Text Embedder probe complete. Dimension=$dimension")
        }
        return dimension
    }

    private fun normalize(v: FloatArray): FloatArray {
        var mag = 0.0
        for (x in v) mag += (x * x).toDouble()
        mag = sqrt(mag)
        if (mag == 0.0) return v
        return FloatArray(v.size) { (v[it] / mag).toFloat() }
    }
}
