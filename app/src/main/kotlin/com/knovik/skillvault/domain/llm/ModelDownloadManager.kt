package com.knovik.skillvault.domain.llm

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.coroutineContext

/**
 * Downloads LLM model files (e.g. from Hugging Face) into the app's private storage,
 * so users don't need adb to install models.
 *
 * Lives in a singleton with its own scope so an active download survives screen
 * navigation. Partial downloads are kept as ".part" files and resumed with HTTP
 * Range requests on the next attempt.
 */
@Singleton
class ModelDownloadManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val okHttpClient: OkHttpClient
) {

    companion object {
        const val LLM_MODEL_FILE_NAME = "gemma-2b-it-cpu-int4.bin"
        const val LLM_MODEL_DISPLAY_NAME = "Gemma 2B IT (CPU, Int4)"
        const val LLM_MODEL_APPROX_SIZE_BYTES = 1_360_000_000L
        const val LLM_MODEL_DEFAULT_URL =
            "https://huggingface.co/a8nova/gemma-2b-it-cpu-int4/resolve/main/gemma-2b-it-cpu-int4.bin"
        const val LLM_MODEL_HF_PAGE = "https://huggingface.co/a8nova/gemma-2b-it-cpu-int4"

        private const val BUFFER_SIZE = 64 * 1024
        private const val PROGRESS_EMIT_INTERVAL_MS = 250L
        // Require some headroom beyond the file itself so the device stays usable
        private const val FREE_SPACE_MARGIN_BYTES = 200_000_000L
    }

    sealed class DownloadState {
        data object Idle : DownloadState()
        data class Downloading(
            val bytesDownloaded: Long,
            val totalBytes: Long,
            val bytesPerSecond: Long
        ) : DownloadState() {
            val percentage: Int
                get() = if (totalBytes > 0) ((bytesDownloaded * 100) / totalBytes).toInt() else 0
        }
        data object Completed : DownloadState()
        data class Failed(val message: String, val canResume: Boolean) : DownloadState()
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var downloadJob: Job? = null

    private val _downloadState = MutableStateFlow<DownloadState>(DownloadState.Idle)
    val downloadState: StateFlow<DownloadState> = _downloadState.asStateFlow()

    private val modelFile: File
        get() = File(context.filesDir, LLM_MODEL_FILE_NAME)

    private val partFile: File
        get() = File(context.filesDir, "$LLM_MODEL_FILE_NAME.part")

    fun isModelInstalled(): Boolean = modelFile.exists()

    fun installedModelSizeBytes(): Long = if (modelFile.exists()) modelFile.length() else 0L

    fun partialDownloadSizeBytes(): Long = if (partFile.exists()) partFile.length() else 0L

    fun isDownloading(): Boolean = downloadJob?.isActive == true

    /**
     * Start (or resume) downloading the model. No-op if a download is already running
     * or the model is installed.
     *
     * @param url Direct download URL. Defaults to a public Hugging Face mirror.
     * @param accessToken Optional Hugging Face access token, required for gated
     *   repos (e.g. official google/gemma). Sent as a Bearer header.
     */
    fun startDownload(
        url: String = LLM_MODEL_DEFAULT_URL,
        accessToken: String? = null
    ) {
        if (isDownloading()) return
        if (isModelInstalled()) {
            _downloadState.value = DownloadState.Completed
            return
        }

        downloadJob = scope.launch {
            runDownload(url.trim(), accessToken?.trim()?.takeIf { it.isNotEmpty() })
        }
    }

    /** Cancel the active download. The partial file is kept so it can be resumed. */
    fun cancelDownload() {
        downloadJob?.cancel()
        downloadJob = null
        _downloadState.value = DownloadState.Failed(
            "Download paused. Tap Download to resume.",
            canResume = true
        )
    }

    /** Delete the installed model (and any partial download) to free up storage. */
    fun deleteModel() {
        downloadJob?.cancel()
        downloadJob = null
        modelFile.delete()
        partFile.delete()
        _downloadState.value = DownloadState.Idle
    }

    private suspend fun runDownload(url: String, accessToken: String?) {
        try {
            if (!url.startsWith("https://")) {
                _downloadState.value = DownloadState.Failed(
                    "Invalid URL: must start with https://", canResume = false
                )
                return
            }

            val resumeFrom = partialDownloadSizeBytes()
            _downloadState.value = DownloadState.Downloading(resumeFrom, 0, 0)

            val requestBuilder = Request.Builder().url(url)
            accessToken?.let { requestBuilder.header("Authorization", "Bearer $it") }
            if (resumeFrom > 0) {
                requestBuilder.header("Range", "bytes=$resumeFrom-")
                Timber.d("Resuming model download from byte $resumeFrom")
            }

            val client = okHttpClient.newBuilder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .build()

            client.newCall(requestBuilder.build()).execute().use { response ->
                if (response.code == 401 || response.code == 403) {
                    _downloadState.value = DownloadState.Failed(
                        "Access denied (HTTP ${response.code}). This model may be gated — " +
                            "accept its license on Hugging Face and provide an access token.",
                        canResume = false
                    )
                    return
                }
                if (!response.isSuccessful) {
                    _downloadState.value = DownloadState.Failed(
                        "Download failed: HTTP ${response.code}",
                        canResume = resumeFrom > 0
                    )
                    return
                }

                // Server ignored the Range request — start over
                val serverResumed = response.code == 206
                var bytesDownloaded = if (serverResumed) resumeFrom else 0L
                if (!serverResumed && resumeFrom > 0) {
                    Timber.d("Server does not support resume, restarting download")
                    partFile.delete()
                }

                val body = response.body ?: run {
                    _downloadState.value = DownloadState.Failed("Empty response", canResume = false)
                    return
                }
                val totalBytes = if (body.contentLength() > 0) {
                    body.contentLength() + (if (serverResumed) resumeFrom else 0L)
                } else 0L

                val freeSpace = context.filesDir.usableSpace
                val needed = (if (totalBytes > 0) totalBytes else LLM_MODEL_APPROX_SIZE_BYTES) -
                    bytesDownloaded + FREE_SPACE_MARGIN_BYTES
                if (freeSpace < needed) {
                    _downloadState.value = DownloadState.Failed(
                        "Not enough storage: need ~${needed / 1_000_000} MB free, " +
                            "have ${freeSpace / 1_000_000} MB.",
                        canResume = bytesDownloaded > 0
                    )
                    return
                }

                body.byteStream().use { input ->
                    FileOutputStream(partFile, serverResumed).use { output ->
                        val buffer = ByteArray(BUFFER_SIZE)
                        var lastEmitTime = System.currentTimeMillis()
                        var bytesSinceEmit = 0L
                        while (true) {
                            coroutineContext.ensureActive()
                            val read = input.read(buffer)
                            if (read == -1) break
                            output.write(buffer, 0, read)
                            bytesDownloaded += read
                            bytesSinceEmit += read

                            val now = System.currentTimeMillis()
                            val elapsed = now - lastEmitTime
                            if (elapsed >= PROGRESS_EMIT_INTERVAL_MS) {
                                _downloadState.value = DownloadState.Downloading(
                                    bytesDownloaded = bytesDownloaded,
                                    totalBytes = totalBytes,
                                    bytesPerSecond = bytesSinceEmit * 1000 / elapsed
                                )
                                lastEmitTime = now
                                bytesSinceEmit = 0L
                            }
                        }
                    }
                }

                if (totalBytes > 0 && bytesDownloaded < totalBytes) {
                    _downloadState.value = DownloadState.Failed(
                        "Connection lost at ${bytesDownloaded / 1_000_000} MB. Tap Download to resume.",
                        canResume = true
                    )
                    return
                }

                if (!partFile.renameTo(modelFile)) {
                    _downloadState.value = DownloadState.Failed(
                        "Could not finalize model file", canResume = false
                    )
                    return
                }
                Timber.d("Model download complete: ${modelFile.length()} bytes")
                _downloadState.value = DownloadState.Completed
            }
        } catch (e: kotlinx.coroutines.CancellationException) {
            throw e
        } catch (e: Exception) {
            Timber.e(e, "Model download failed")
            _downloadState.value = DownloadState.Failed(
                "Download error: ${e.message ?: "unknown"}. Tap Download to retry/resume.",
                canResume = partialDownloadSizeBytes() > 0
            )
        }
    }

}
