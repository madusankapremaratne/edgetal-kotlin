package com.knovik.edgetal

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Native side of the `edgetal/embedder` channel — the on-device text embedder.
 *
 * This mirrors the original EdgeTal `MediaPipeEmbeddingProvider`. To activate
 * the true on-device pipeline:
 *   1. Add the MediaPipe Tasks Text dependency in `android/app/build.gradle`:
 *        implementation("com.google.mediapipe:tasks-text:0.10.21")
 *   2. Ship `text_embedder.tflite` in `android/app/src/main/assets/`.
 *   3. Implement the two TODOs below using `com.google.mediapipe.tasks.text
 *      .textembedder.TextEmbedder`.
 *
 * Until then, returning errors here is harmless: the Dart `NativeEmbeddingProvider`
 * falls back to its offline hashing embedder.
 */
class EmbedderChannel(private val context: Context) {

    // private var embedder: TextEmbedder? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "edgetal/embedder").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    // TODO: build TextEmbedder from assets/text_embedder.tflite and
                    // return the embedding dimension (512). Example:
                    //
                    // val options = TextEmbedder.TextEmbedderOptions.builder()
                    //     .setBaseOptions(
                    //         BaseOptions.builder()
                    //             .setModelAssetPath("text_embedder.tflite").build())
                    //     .build()
                    // embedder = TextEmbedder.createFromOptions(context, options)
                    // result.success(512)
                    result.error("UNIMPLEMENTED", "MediaPipe embedder not wired yet", null)
                }
                "embed" -> {
                    // val text = call.argument<String>("text") ?: ""
                    // val embedding = embedder!!.embed(text).embeddingResult()
                    //     .embeddings().first().floatEmbedding()
                    // result.success(embedding.toList())
                    result.error("UNIMPLEMENTED", "MediaPipe embedder not wired yet", null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
