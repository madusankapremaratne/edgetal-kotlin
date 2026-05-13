package com.knovik.skillvault.ui.benchmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.knovik.skillvault.data.entity.PerformanceMetric
import com.knovik.skillvault.data.repository.ResumeRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class BenchmarksViewModel @Inject constructor(
    private val resumeRepository: ResumeRepository,
    private val embeddingProvider: com.knovik.skillvault.domain.embedding.MediaPipeEmbeddingProvider,
    private val vectorSearchEngine: com.knovik.skillvault.domain.vector_search.VectorSearchEngine,
    private val searchAgent: com.knovik.skillvault.domain.llm.SearchAgent,
    private val performanceMonitor: com.knovik.skillvault.domain.monitor.PerformanceMonitor
) : ViewModel() {

    private val _metrics = MutableStateFlow<List<PerformanceMetric>>(emptyList())
    val metrics: StateFlow<List<PerformanceMetric>> = _metrics.asStateFlow()

    private val _summary = MutableStateFlow<BenchmarkSummary>(BenchmarkSummary())
    val summary: StateFlow<BenchmarkSummary> = _summary.asStateFlow()

    private val _isBenchmarking = MutableStateFlow(false)
    val isBenchmarking: StateFlow<Boolean> = _isBenchmarking.asStateFlow()

    private val testQueries = listOf(
        "Android Developer", // Simple
        "Building scalable mobile architectures", // Abstract
        "Senior Kotlin developer with Clean Architecture knowledge", // Multi-attribute
        "Data Scientist with Python and Machine Learning expertise", // Technical
        "Experience in high-volume data processing and cloud infrastructure" // Conceptual
    )

    init {
        loadMetrics()
    }

    fun runAutoBenchmark() {
        viewModelScope.launch {
            try {
                _isBenchmarking.value = true
                
                // Ensure provider is initialized
                embeddingProvider.initialize()

                for (query in testQueries) {
                    Timber.d("Benchmarking query: $query")
                    
                    // 1. Keyword Baseline (simulated)
                    val startTimeKeyword = System.currentTimeMillis()
                    resumeRepository.searchResumesByKeyword(query)
                    val durationKeyword = System.currentTimeMillis() - startTimeKeyword
                    performanceMonitor.recordLatency("keyword_baseline", "Baseline: $query", durationKeyword)

                    // 2. Static Vector Search
                    val startTimeVector = System.currentTimeMillis()
                    val embedding = embeddingProvider.embedText(query).getOrThrow()
                    val candidates = resumeRepository.getAllEmbeddings()
                    val results = vectorSearchEngine.search(embedding, candidates)
                    val durationVector = System.currentTimeMillis() - startTimeVector
                    performanceMonitor.recordLatency("retrieval", "Static Search: $query", durationVector, results.size)

                    // 3. Agentic Search (with Reformulation)
                    val startTimeAgentic = System.currentTimeMillis()
                    // Simulate reformulation trigger
                    val reformulated = searchAgent.reformulateQuery(query, results)
                    val refEmbedding = embeddingProvider.embedText(reformulated).getOrThrow()
                    val finalResults = vectorSearchEngine.search(refEmbedding, candidates)
                    val durationAgentic = System.currentTimeMillis() - startTimeAgentic
                    
                    performanceMonitor.recordLatency(
                        "agentic_search", 
                        "Reformulated: $query -> $reformulated", 
                        durationAgentic, 
                        finalResults.size
                    )
                    
                    // Small delay to prevent resource contention
                    kotlinx.coroutines.delay(500)
                }

                loadMetrics()
            } catch (e: Exception) {
                Timber.e(e, "Benchmark failed")
            } finally {
                _isBenchmarking.value = false
            }
        }
    }

    fun loadMetrics() {
        viewModelScope.launch {
            val allMetrics = resumeRepository.getAllPerformanceMetrics()
            _metrics.value = allMetrics
            calculateSummary(allMetrics)
        }
    }

    private fun calculateSummary(allMetrics: List<PerformanceMetric>) {
        val ingestion = allMetrics.filter { it.operationType == "ingestion" }
        val retrieval = allMetrics.filter { it.operationType == "retrieval" }
        val reasoning = allMetrics.filter { it.operationType == "agentic_reasoning" }
        val reformulation = allMetrics.filter { it.operationType == "agentic_search" }

        _summary.value = BenchmarkSummary(
            avgIngestionMs = ingestion.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            avgRetrievalMs = retrieval.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            avgReasoningMs = reasoning.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            avgReformulationMs = reformulation.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            totalCount = allMetrics.size,
            deviceInfo = allMetrics.firstOrNull()?.let { "${it.manufacturer} ${it.model}" } ?: "Unknown"
        )
    }

    fun clearMetrics() {
        viewModelScope.launch {
            resumeRepository.clearPerformanceMetrics()
            loadMetrics()
        }
    }

    fun getExportCsvContent(): String {
        val header = "Timestamp,Type,Operation,Duration(ms),Resumes,Embeddings,Device,Context\n"
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        
        val rows = _metrics.value.joinToString("\n") { metric ->
            listOf(
                dateFormat.format(Date(metric.timestamp)),
                metric.operationType,
                metric.operationName.replace(",", ";"), // Escape comma
                metric.durationMs.toString(),
                metric.resumeCount.toString(),
                metric.embeddingCount.toString(),
                "${metric.manufacturer} ${metric.model}",
                metric.contextData.replace(",", ";") // Escape comma
            ).joinToString(",")
        }
        
        return header + rows
    }
}

data class BenchmarkSummary(
    val avgIngestionMs: Double = 0.0,
    val avgRetrievalMs: Double = 0.0,
    val avgReasoningMs: Double = 0.0,
    val avgReformulationMs: Double = 0.0,
    val totalCount: Int = 0,
    val deviceInfo: String = ""
)
