package com.knovik.skillvault.ui.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.knovik.skillvault.data.entity.SearchQuery
import com.knovik.skillvault.data.repository.ResumeRepository
import com.knovik.skillvault.domain.embedding.MediaPipeEmbeddingProvider
import com.knovik.skillvault.domain.vector_search.SearchResult
import com.knovik.skillvault.domain.vector_search.VectorSearchEngine
import com.knovik.skillvault.domain.llm.LlmInferenceProvider
import com.knovik.skillvault.domain.llm.SearchAgent
import com.knovik.skillvault.domain.monitor.PerformanceMonitor
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * UI state for search results.
 */
sealed class SearchUIState {
    data object Idle : SearchUIState()
    data object Loading : SearchUIState()
    data class AgenticLoading(val step: String) : SearchUIState()
    data class Success(val results: List<SearchResultUi>, val reformulatedQuery: String? = null) : SearchUIState()
    data class Error(val message: String) : SearchUIState()
}

/**
 * UI model for search result with resume details.
 */
data class SearchResultUi(
    val searchResult: SearchResult,
    val resume: com.knovik.skillvault.data.entity.Resume?
)

/**
 * ViewModel for semantic search screen.
 * Handles query embedding and vector similarity search.
 */
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val resumeRepository: ResumeRepository,
    private val embeddingProvider: MediaPipeEmbeddingProvider,
    private val vectorSearchEngine: VectorSearchEngine,
    private val searchAgent: SearchAgent,
    private val performanceMonitor: PerformanceMonitor
) : ViewModel() {

    private val _uiState = MutableStateFlow<SearchUIState>(SearchUIState.Idle)
    val uiState: StateFlow<SearchUIState> = _uiState.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _executionTimeMs = MutableStateFlow(0L)
    val executionTimeMs: StateFlow<Long> = _executionTimeMs.asStateFlow()

    private val _resultCount = MutableStateFlow(0)
    val resultCount: StateFlow<Int> = _resultCount.asStateFlow()

    init {
        initializeEmbeddingProvider()
    }

    private fun initializeEmbeddingProvider() {
        viewModelScope.launch {
            try {
                val result = embeddingProvider.initialize()
                if (result.isSuccess) {
                    Timber.d("Embedding provider initialized")
                } else {
                    Timber.e(result.exceptionOrNull(), "Failed to initialize embedding provider")
                    _uiState.value = SearchUIState.Error("Failed to initialize embedding engine")
                }
            } catch (e: Exception) {
                Timber.e(e, "Exception during embedding provider initialization")
            }
        }
    }

    /**
     * Standard Search - Static RAG Pipeline
     */
    fun search(
        query: String,
        topK: Int = 10,
        segmentFilter: String? = null,
    ) {
        if (query.isBlank()) {
            _uiState.value = SearchUIState.Idle
            return
        }

        viewModelScope.launch {
            performSearch(query, topK, segmentFilter)
        }
    }

    /**
     * Agentic Search - Feedback-Driven Query Reformulation
     */
    fun agenticSearch(
        query: String,
        topK: Int = 10,
        userFeedback: String? = null
    ) {
        if (query.isBlank()) {
            _uiState.value = SearchUIState.Idle
            return
        }

        viewModelScope.launch {
            try {
                _uiState.value = SearchUIState.AgenticLoading("Performing initial search...")
                
                // 1. Initial Search
                val initialResults = performSearchInternal(query, topK)
                
                // 2. Decide if reformulation is needed
                // Rule: If top score is low (< 0.6) or results are few, or user provided feedback
                val needsReformulation = initialResults.isEmpty() || 
                                        (initialResults.firstOrNull()?.similarityScore ?: 0f) < 0.6f ||
                                        !userFeedback.isNullOrBlank()

                if (needsReformulation) {
                    _uiState.value = SearchUIState.AgenticLoading("Reformulating query based on results...")
                    
                    val startTime = System.currentTimeMillis()
                    val reformulated = searchAgent.reformulateQuery(query, initialResults, userFeedback)
                    val duration = System.currentTimeMillis() - startTime
                    
                    performanceMonitor.recordLatency("agentic_search", "Query Reformulation", duration)
                    
                    _uiState.value = SearchUIState.AgenticLoading("Searching with optimized query: \"$reformulated\"")
                    
                    // 3. Search again with reformulated query
                    val finalResults = performSearchInternal(reformulated, topK)
                    
                    _uiState.value = SearchUIState.Success(
                        results = wrapResults(finalResults),
                        reformulatedQuery = reformulated
                    )
                } else {
                    _uiState.value = SearchUIState.Success(wrapResults(initialResults))
                }

            } catch (e: Exception) {
                Timber.e(e, "Agentic search failed")
                _uiState.value = SearchUIState.Error(e.message ?: "Unknown error")
            }
        }
    }

    private suspend fun performSearch(query: String, topK: Int, segmentFilter: String?) {
        try {
            _uiState.value = SearchUIState.Loading
            val results = performSearchInternal(query, topK, segmentFilter)
            _uiState.value = SearchUIState.Success(wrapResults(results))
        } catch (e: Exception) {
            _uiState.value = SearchUIState.Error(e.message ?: "Search failed")
        }
    }

    private suspend fun performSearchInternal(
        query: String, 
        topK: Int, 
        segmentFilter: String? = null
    ): List<SearchResult> {
        _searchQuery.value = query
        val startTime = System.currentTimeMillis()

        // Generate embedding
        val embeddingResult = embeddingProvider.embedText(query)
        val queryEmbedding = embeddingResult.getOrThrow()

        // Get candidates
        val candidates = resumeRepository.getAllEmbeddings()
        if (candidates.isEmpty()) throw IllegalStateException("No resumes imported")

        // Vector search
        val results = if (segmentFilter != null) {
            vectorSearchEngine.searchBySegmentType(queryEmbedding, candidates, segmentFilter, topK)
        } else {
            vectorSearchEngine.search(queryEmbedding, candidates, topK)
        }

        val endTime = System.currentTimeMillis()
        val executionTime = endTime - startTime
        
        _executionTimeMs.value = executionTime
        _resultCount.value = results.size

        // Analytics
        resumeRepository.recordSearchQuery(SearchQuery(
            queryText = query,
            queryEmbedding = queryEmbedding,
            executionTimeMs = executionTime,
            resultCount = results.size,
            topScoreValue = results.firstOrNull()?.similarityScore ?: 0f,
        ))

        return results
    }

    private suspend fun wrapResults(results: List<SearchResult>): List<SearchResultUi> {
        return results.map { result ->
            val resume = resumeRepository.getResume(result.resumeId)
            SearchResultUi(result, resume)
        }
    }

    fun clearSearch() {
        _uiState.value = SearchUIState.Idle
        _searchQuery.value = ""
        _executionTimeMs.value = 0
        _resultCount.value = 0
    }

    fun recordSearchFeedback(satisfied: Boolean, feedbackText: String = "") {
        viewModelScope.launch {
            try {
                val history = resumeRepository.getSearchHistory(1)
                if (history.isNotEmpty()) {
                    val lastQuery = history.first()
                    lastQuery.wasUserSatisfied = satisfied
                    lastQuery.feedbackText = feedbackText
                    resumeRepository.recordSearchQuery(lastQuery)
                    
                    // If user was NOT satisfied, trigger agentic reformulation search
                    if (!satisfied && feedbackText.isNotBlank()) {
                        agenticSearch(_searchQuery.value, userFeedback = feedbackText)
                    }
                }
            } catch (e: Exception) {
                Timber.e(e, "Failed to record feedback")
            }
        }
    }
}
