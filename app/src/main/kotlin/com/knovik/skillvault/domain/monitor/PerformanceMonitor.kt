package com.knovik.skillvault.domain.monitor

import android.os.Build
import com.knovik.skillvault.data.entity.PerformanceMetric
import com.knovik.skillvault.data.repository.ResumeRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Utility to monitor and record performance benchmarks for the agentic RAG pipeline.
 * Supports the empirical evaluation contribution of the study.
 */
@Singleton
class PerformanceMonitor @Inject constructor(
    private val repository: ResumeRepository
) {
    private val monitorScope = CoroutineScope(Dispatchers.IO)
    private val deviceInfo = "${Build.MANUFACTURER} ${Build.MODEL} (Android ${Build.VERSION.RELEASE})"

    /**
     * Record a latency metric (time-based).
     */
    fun recordLatency(
        type: String,
        name: String,
        durationMs: Long,
        resumeCount: Int = 0,
        embeddingCount: Int = 0
    ) {
        val metric = PerformanceMetric(
            metricType = type,
            metricName = name,
            value = durationMs.toDouble(),
            unit = "ms",
            resumeCount = resumeCount,
            embeddingCount = embeddingCount,
            deviceInfo = deviceInfo
        )
        saveMetric(metric)
    }

    /**
     * Record a storage metric (size-based).
     */
    fun recordStorage(
        name: String,
        sizeMb: Double,
        resumeCount: Int = 0
    ) {
        val metric = PerformanceMetric(
            metricType = "storage",
            metricName = name,
            value = sizeMb,
            unit = "MB",
            resumeCount = resumeCount,
            deviceInfo = deviceInfo
        )
        saveMetric(metric)
    }

    /**
     * Record LLM throughput (tokens per second).
     */
    fun recordThroughput(
        name: String,
        tokensPerSecond: Double
    ) {
        val metric = PerformanceMetric(
            metricType = "inference",
            metricName = name,
            value = tokensPerSecond,
            unit = "t/s",
            deviceInfo = deviceInfo
        )
        saveMetric(metric)
    }

    private fun saveMetric(metric: PerformanceMetric) {
        monitorScope.launch {
            try {
                repository.recordMetric(metric)
            } catch (e: Exception) {
                // Fail silently in monitoring to avoid impacting main flows
            }
        }
    }
}
