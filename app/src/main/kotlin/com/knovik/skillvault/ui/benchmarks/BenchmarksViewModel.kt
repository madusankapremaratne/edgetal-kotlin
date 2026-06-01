package com.knovik.skillvault.ui.benchmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.knovik.skillvault.data.entity.PerformanceMetric
import com.knovik.skillvault.data.entity.Resume
import com.knovik.skillvault.data.repository.ResumeRepository
import com.knovik.skillvault.domain.embedding.MediaPipeEmbeddingProvider
import com.knovik.skillvault.domain.llm.LlmInferenceProvider
import com.knovik.skillvault.domain.llm.SearchAgent
import com.knovik.skillvault.domain.monitor.PerformanceMonitor
import com.knovik.skillvault.domain.vector_search.VectorSearchEngine
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class BenchmarksViewModel @Inject constructor(
    private val resumeRepository: ResumeRepository,
    private val embeddingProvider: MediaPipeEmbeddingProvider,
    private val vectorSearchEngine: VectorSearchEngine,
    private val searchAgent: SearchAgent,
    private val llmProvider: LlmInferenceProvider,
    private val performanceMonitor: PerformanceMonitor
) : ViewModel() {

    private val _metrics = MutableStateFlow<List<PerformanceMetric>>(emptyList())
    val metrics: StateFlow<List<PerformanceMetric>> = _metrics.asStateFlow()

    private val _summary = MutableStateFlow<BenchmarkSummary>(BenchmarkSummary())
    val summary: StateFlow<BenchmarkSummary> = _summary.asStateFlow()

    private val _isBenchmarking = MutableStateFlow(false)
    val isBenchmarking: StateFlow<Boolean> = _isBenchmarking.asStateFlow()

    // 15-Query Evaluation Protocol for PhD Research
    private val testQueries = listOf(
        // Tier 1: Direct Semantic (Keyword-adjacent)
        "Android Developer",
        "Data Scientist",
        "Database Administrator",
        "HR Officer",
        "Project Coordinator",
        
        // Tier 2: Abstract Intent (Conceptual)
        "Building scalable mobile architectures",
        "Expert in deep learning and NLP",
        "Managing complex technical teams",
        "Securing cloud infrastructure",
        "Designing high-performance backend systems",
        
        // Tier 3: Multi-attribute (Recruiter Query)
        "Senior Kotlin developer with Clean Architecture knowledge",
        "Data Scientist with Python and Machine Learning expertise",
        "Experience in high-volume data processing and cloud infrastructure",
        "Recruitment specialist with technical interviewing skills",
        "Infrastructure engineer with DevOps and CI/CD focus"
    )

    // Ground Truth mapping for Precision calculation
    private val groundTruthKeywords = mapOf(
        "Android Developer" to listOf("android", "ios", "mobile", "developer"),
        "Data Scientist" to listOf("data scientist", "machine learning", "nlp", "analyst"),
        "Database Administrator" to listOf("database", "dba", "sql", "administrator"),
        "HR Officer" to listOf("hr", "human resource", "recruiter", "compliance"),
        "Project Coordinator" to listOf("project", "coordinator", "manager", "planning"),
        "Building scalable mobile architectures" to listOf("android", "ios", "mobile", "developer", "architecture"),
        "Expert in deep learning and NLP" to listOf("machine learning", "nlp", "deep learning", "scientist"),
        "Managing complex technical teams" to listOf("manager", "lead", "coordination", "collaboration"),
        "Securing cloud infrastructure" to listOf("cloud", "security", "infrastructure", "devops"),
        "Designing high-performance backend systems" to listOf("developer", "software", "backend", "system", "performance"),
        "Senior Kotlin developer with Clean Architecture knowledge" to listOf("android", "kotlin", "developer", "architecture"),
        "Data Scientist with Python and Machine Learning expertise" to listOf("data scientist", "python", "machine learning"),
        "Experience in high-volume data processing and cloud infrastructure" to listOf("big data", "cloud", "infrastructure", "data analytics"),
        "Recruitment specialist with technical interviewing skills" to listOf("hr", "recruiter", "interview", "management"),
        "Infrastructure engineer with DevOps and CI/CD focus" to listOf("devops", "infrastructure", "ci/cd", "engineer")
    )

    init {
        loadMetrics()
    }

    fun runAutoBenchmark() {
        viewModelScope.launch {
            try {
                _isBenchmarking.value = true
                
                // Ensure providers are initialized
                embeddingProvider.initialize()
                llmProvider.initialize()

                val allCandidates = resumeRepository.getAllEmbeddings().take(1500)

                for (query in testQueries) {
                    Timber.d("Benchmarking query: $query")
                    
                    // 1. Keyword Baseline
                    val startTimeKeyword = System.currentTimeMillis()
                    val keywordResults = resumeRepository.searchResumesByKeyword(query)
                    val durationKeyword = System.currentTimeMillis() - startTimeKeyword
                    val precisionKeyword = calculatePrecision(query, keywordResults, k = 5)
                    performanceMonitor.recordLatency(
                        "keyword_baseline", 
                        "Baseline: $query", 
                        durationKeyword, 
                        keywordResults.size,
                        precision = precisionKeyword
                    )

                    // 2. Static Vector Search
                    val startTimeVector = System.currentTimeMillis()
                    val embedding = embeddingProvider.embedText(query).getOrThrow()
                    val staticResults = vectorSearchEngine.search(embedding, allCandidates)
                    val durationVector = System.currentTimeMillis() - startTimeVector
                    
                    // Need to fetch full entities for category check
                    val staticResumes = staticResults.mapNotNull { resumeRepository.getResume(it.resumeId) }
                    val precisionStatic = calculatePrecision(query, staticResumes, k = 5)
                    
                    performanceMonitor.recordLatency(
                        "retrieval", 
                        "Static Search: $query", 
                        durationVector, 
                        staticResults.size,
                        precision = precisionStatic
                    )

                    // 3. Agentic Search (with Reformulation)
                    val startTimeAgentic = System.currentTimeMillis()
                    val reformulated = searchAgent.reformulateQuery(query, staticResults)
                    val refEmbedding = embeddingProvider.embedText(reformulated).getOrThrow()
                    val agenticResults = vectorSearchEngine.search(refEmbedding, allCandidates)
                    val durationAgentic = System.currentTimeMillis() - startTimeAgentic
                    
                    val agenticResumes = agenticResults.mapNotNull { resumeRepository.getResume(it.resumeId) }
                    val precisionAgentic = calculatePrecision(query, agenticResumes, k = 5)
                    
                    performanceMonitor.recordLatency(
                        "agentic_search", 
                        "Reformulated: $query -> $reformulated", 
                        durationAgentic, 
                        agenticResults.size,
                        precision = precisionAgentic
                    )
                    
                    // Small delay to prevent resource contention
                    delay(1000)
                }

                loadMetrics()
            } catch (e: Exception) {
                Timber.e(e, "Benchmark failed")
            } finally {
                _isBenchmarking.value = false
            }
        }
    }

    private fun calculatePrecision(query: String, results: List<Resume>, k: Int): Double {
        if (results.isEmpty()) return 0.0
        
        val topK = results.take(k)
        val validKeywords = groundTruthKeywords[query] ?: return 0.0
        
        var relevantCount = 0
        Timber.d("Evaluating precision for: $query (Top $k)")
        
        for (resume in topK) {
            val category = resume.category.lowercase()
            val fullName = resume.fullName.lowercase()
            val skills = resume.skills.lowercase()
            
            // Flexible matching: check category, name, or skills
            val isRelevant = validKeywords.any { 
                category.contains(it) || fullName.contains(it) || (it.length > 3 && skills.contains(it))
            }
            
            if (isRelevant) {
                relevantCount++
            }
            Timber.v("  - Candidate [${resume.id}]: Category='$category', Relevant=$isRelevant")
        }
        
        val precision = relevantCount.toDouble() / topK.size
        Timber.d("  => Precision@$k: %.2f", precision)
        return precision
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
        val agentic = allMetrics.filter { it.operationType == "agentic_search" }
        val baseline = allMetrics.filter { it.operationType == "keyword_baseline" }

        _summary.value = BenchmarkSummary(
            avgIngestionMs = ingestion.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            avgRetrievalMs = retrieval.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            avgAgenticMs = agentic.map { it.durationMs.toDouble() }.average().takeIf { !it.isNaN() } ?: 0.0,
            meanPrecisionStatic = retrieval.map { it.precision }.average().takeIf { !it.isNaN() } ?: 0.0,
            meanPrecisionAgentic = agentic.map { it.precision }.average().takeIf { !it.isNaN() } ?: 0.0,
            meanPrecisionBaseline = baseline.map { it.precision }.average().takeIf { !it.isNaN() } ?: 0.0,
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
        val header = "Timestamp,Type,Operation,Duration(ms),Precision,Resumes,Embeddings,Device,Context\n"
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        
        val rows = _metrics.value.joinToString("\n") { metric ->
            listOf(
                dateFormat.format(Date(metric.timestamp)),
                metric.operationType,
                metric.operationName.replace(",", ";"),
                metric.durationMs.toString(),
                "%.2f".format(metric.precision),
                metric.resumeCount.toString(),
                metric.embeddingCount.toString(),
                "${metric.manufacturer} ${metric.model}",
                metric.contextData.replace(",", ";")
            ).joinToString(",")
        }
        
        return header + rows
    }
}

data class BenchmarkSummary(
    val avgIngestionMs: Double = 0.0,
    val avgRetrievalMs: Double = 0.0,
    val avgAgenticMs: Double = 0.0,
    val meanPrecisionStatic: Double = 0.0,
    val meanPrecisionAgentic: Double = 0.0,
    val meanPrecisionBaseline: Double = 0.0,
    val totalCount: Int = 0,
    val deviceInfo: String = ""
)
