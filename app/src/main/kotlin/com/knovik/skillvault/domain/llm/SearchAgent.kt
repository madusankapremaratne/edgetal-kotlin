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
            results.take(3).joinToString("\n") { "- ${it.segmentText.take(100)}..." }
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
            Analyze why the original query might be failing or how it could be improved to find better candidates.
            Generate a single, optimized search query that is more descriptive and uses better keywords.
            
            INSTRUCTIONS:
            1. [ANALYSIS]: Briefly analyze the mismatch.
            2. [NEW_QUERY]: The improved search string.
            
            Format:
            ANALYSIS: (your analysis)
            NEW_QUERY: (the new query string only)
            <end_of_turn>
            <start_of_turn>model
            ANALYSIS:
        """.trimIndent()
    }

    private fun parseReformulatedQuery(response: String, originalQuery: String): String {
        val newQuery = response.substringAfter("NEW_QUERY:", "").trim()
        return if (newQuery.isNotEmpty()) {
            // Clean up any quotes or prefixes the model might have added
            newQuery.removeSurrounding("\"").removeSurrounding("'")
        } else {
            // Fallback: if model just gave text, try to extract the last line or stay original
            if (response.lines().last().isNotEmpty()) response.lines().last() else originalQuery
        }
    }
}
