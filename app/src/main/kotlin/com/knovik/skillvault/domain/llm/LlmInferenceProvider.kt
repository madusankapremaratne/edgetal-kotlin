package com.knovik.skillvault.domain.llm

import android.content.Context
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import timber.log.Timber
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Provider for on-device LLM inference using MediaPipe and Gemma 2.
 * Updated for MediaPipe 0.10.18+ Session API.
 */
@Singleton
class LlmInferenceProvider @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var llmInference: LlmInference? = null
    private var llmSession: LlmInferenceSession? = null
    private val modelFileName = "gemma-2b-it-cpu-int4.bin"
    private val initializationMutex = Mutex()

    /**
     * Initialize the LLM engine and session.
     */
    suspend fun initialize(): Result<Unit> = withContext(Dispatchers.IO) {
        initializationMutex.withLock {
            try {
                if (llmSession != null) return@withLock Result.success(Unit)

                val sourceFile = File(context.filesDir, modelFileName)
                if (!sourceFile.exists()) {
                    return@withLock Result.failure(
                        IllegalStateException("Model file not found. Please push '$modelFileName' to ${context.filesDir.absolutePath}")
                    )
                }

                // 1. Initialize the base engine
                val options = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(sourceFile.absolutePath)
                    .setMaxTokens(512)
                    .setErrorListener { error: RuntimeException -> 
                        Timber.e("Native LLM Error: ${error.message}")
                    }
                    .build()

                val inference = LlmInference.createFromOptions(context, options)
                llmInference = inference

                // 2. Initialize the session with generation parameters
                val sessionOptions = LlmInferenceSession.LlmInferenceSessionOptions.builder()
                    .setTemperature(0.7f)
                    .setRandomSeed(42)
                    .build()

                llmSession = LlmInferenceSession.createFromOptions(inference, sessionOptions)
                
                Timber.d("LLM Inference and Session initialized successfully")
                Result.success(Unit)
            } catch (e: Exception) {
                Timber.e(e, "Failed to initialize LLM Inference")
                Result.failure(e)
            }
        }
    }

    /**
     * Generate a response for the given prompt.
     */
    suspend fun generateResponse(prompt: String): String = withContext(Dispatchers.IO) {
        try {
            if (llmSession == null) {
                val initResult = initialize()
                if (initResult.isFailure) throw initResult.exceptionOrNull()!!
            }
            
            // In 0.10.18+, you add the query chunk first, then generate the response
            llmSession?.addQueryChunk(prompt)
            val result = llmSession?.generateResponse()
            if (result == null) {
                Timber.e("LLM Session returned null response")
                return@withContext ""
            }
            result
        } catch (e: Exception) {
            Timber.e(e, "LLM generation failed")
            throw e
        }
    }

    fun isModelAvailable(): Boolean {
        return File(context.filesDir, modelFileName).exists()
    }
}
