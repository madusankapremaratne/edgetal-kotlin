package com.knovik.skillvault.domain.llm

import com.knovik.skillvault.data.entity.Resume
import com.knovik.skillvault.domain.monitor.PerformanceMonitor
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Agent steps for the UI to observe the reasoning process.
 */
sealed class AgentStep {
    data class Thinking(val message: String) : AgentStep()
    data class Processing(val message: String) : AgentStep()
    data class FinalResult(val content: String, val reasoning: String) : AgentStep()
    data class Error(val message: String) : AgentStep()
}

/**
 * Reasoning Agent (Act Phase).
 * Performs deep semantic evaluation of candidates using a local LLM.
 * Implements Chain-of-Thought reasoning.
 */
@Singleton
class CandidateAgent @Inject constructor(
    private val llmProvider: LlmInferenceProvider,
    private val performanceMonitor: PerformanceMonitor
) {

    /**
     * Evaluates a candidate using an agentic reasoning workflow.
     */
    fun evaluateCandidate(resume: Resume, roleDescription: String): Flow<AgentStep> = flow {
        val startTime = System.currentTimeMillis()
        try {
            emit(AgentStep.Thinking("Extracting key requirements from Job Description..."))
            
            // For edge LLMs, we combine the thinking and answering into a single structured prompt
            // to minimize the number of inference passes while still following an agentic flow.
            
            val prompt = buildAgenticPrompt(resume, roleDescription)
            
            emit(AgentStep.Processing("Analyzing candidate evidence against requirements..."))
            
            val response = llmProvider.generateResponse(prompt)
            
            // Parse the response to separate reasoning from result
            val (reasoning, result) = parseAgentResponse(response)
            
            val durationMs = System.currentTimeMillis() - startTime
            performanceMonitor.recordLatency(
                type = "agentic_reasoning",
                name = "Candidate Evaluation",
                durationMs = durationMs
            )
            
            emit(AgentStep.FinalResult(result, reasoning))
            
        } catch (e: Exception) {
            Timber.e(e, "Agent evaluation failed")
            emit(AgentStep.Error(e.message ?: "Unknown error occurred during analysis"))
        }
    }

    private fun buildAgenticPrompt(resume: Resume, roleDescription: String): String {
        return """
            <start_of_turn>user
            You are an expert HR Recruitment Agent. Perform a deep analysis of the candidate fit for the following role.
            
            ROLE DESCRIPTION:
            $roleDescription
            
            CANDIDATE DATA:
            Summary: ${resume.summary}
            Skills: ${resume.skills}
            Experience: ${resume.experience}
            
            INSTRUCTIONS:
            Perform your analysis in three distinct steps:
            1. [THOUGHT]: Identify the core 3 technical requirements for this role.
            2. [EVIDENCE]: Find specific evidence in the candidate's data (skills or experience) that matches or contradicts these requirements.
            3. [CONCLUSION]: Provide a final recommendation (Yes/No/Maybe) with a brief summary.
            
            Format your response exactly as follows:
            THOUGHT: (your analysis here)
            EVIDENCE: (your extracted evidence here)
            CONCLUSION: (your final answer here)
            <end_of_turn>
            <start_of_turn>model
            THOUGHT:
        """.trimIndent()
    }

    private fun parseAgentResponse(response: String): Pair<String, String> {
        val thoughtPart = response.substringAfter("THOUGHT:", "").substringBefore("EVIDENCE:").trim()
        val evidencePart = response.substringAfter("EVIDENCE:", "").substringBefore("CONCLUSION:").trim()
        val conclusionPart = response.substringAfter("CONCLUSION:", "").trim()
        
        val reasoning = if (thoughtPart.isNotEmpty() || evidencePart.isNotEmpty()) {
            "**Analysis:**\n$thoughtPart\n\n**Evidence Found:**\n$evidencePart"
        } else {
            "No detailed reasoning provided."
        }
        
        val result = conclusionPart.ifEmpty { 
            // Fallback if the model didn't follow formatting perfectly
            if (response.contains("CONCLUSION:")) response.substringAfter("CONCLUSION:") else response 
        }
        
        return Pair(reasoning, result)
    }
}
