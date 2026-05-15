package com.knovik.skillvault.domain.llm

import com.knovik.skillvault.domain.vector_search.SearchResult
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Query Understanding Agent (Plan Phase).
 * Responsible for query expansion and reformulation based on search feedback.
 * This implements the "Agentic RAG" logic required for the study.
 */
@Singleton
class SearchAgent @Inject constructor(
    private val llmProvider: LlmInferenceProvider
) {

    /**
     * Reformulates a search query based on initial results and optional feedback.
     * Uses the local LLM to "think" about what the user actually wants.
     */
    suspend fun reformulateQuery(
        originalQuery: String,
        results: List<SearchResult>,
        userFeedback: String? = null
    ): String {
        try {
            val prompt = buildReformulationPrompt(originalQuery, results, userFeedback)
            val response = llmProvider.generateResponse(prompt)
            
            // Extract the reformulated query from the response
            return parseReformulatedQuery(response, originalQuery)
        } catch (e: Exception) {
            Timber.e(e, "Query reformulation failed")
            return originalQuery // Fallback to original
        }
    }

    private fun buildReformulationPrompt(
        originalQuery: String,
        results: List<SearchResult>,
        userFeedback: String?
    ): String {
        val resultContext = if (results.isNotEmpty()) {
            results.take(2).joinToString("\n") { "- ${it.segmentText.take(70)}..." }
        } else {
            "No relevant results found."
        }

        val feedbackSection = if (!userFeedback.isNullOrBlank()) {
            "\nUSER FEEDBACK: $userFeedback"
        } else {
            ""
        }

        return """
            <start_of_turn>user
            You are a Search Optimization Agent. Your goal is to improve a talent search query.
            
            ORIGINAL QUERY: $originalQuery
            $feedbackSection
            
            CURRENT RESULTS PREVIEW:
            $resultContext
            
            TASK: 
            Analyze the mismatch and generate a single, optimized search query.
            The optimized query must be a natural language description of the ideal candidate.
            
            CRITICAL CONSTRAINTS:
            - DO NOT use keyword-stuffing (e.g., "skills; jobs; openings").
            - DO NOT include your analysis or explanation in the NEW_QUERY section.
            - DO NOT hallucinate context not present in the original query or results.
            - ONLY provide a semantic, descriptive query.
            
            Format:
            ANALYSIS: (1 sentence why the change is needed)
            NEW_QUERY: (the optimized query string only)
            <end_of_turn>
            <start_of_turn>model
            ANALYSIS:
        """.trimIndent()
    }

    private fun parseReformulatedQuery(response: String, originalQuery: String): String {
        // Look specifically for NEW_QUERY tag
        val newQuery = response
            .substringAfter("NEW_QUERY:", "")
            .lines()
            .firstOrNull { it.isNotBlank() }
            ?.trim()
            ?.removeSurrounding("\"")
            ?.removeSurrounding("'")
            ?.take(150) // Hard cap to prevent runaway output
        
        return if (!newQuery.isNullOrBlank() && newQuery != originalQuery) {
            newQuery
        } else {
            originalQuery
        }
    }
}
