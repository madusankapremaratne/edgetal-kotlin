package com.knovik.skillvault.ui.llm_chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.knovik.skillvault.data.repository.ResumeRepository
import com.knovik.skillvault.domain.llm.AgentStep
import com.knovik.skillvault.domain.llm.CandidateAgent
import com.knovik.skillvault.domain.llm.LlmInferenceProvider
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

sealed class ChatUiState {
    data object Idle : ChatUiState()
    data object Loading : ChatUiState()
    data class AgenticLoading(val step: String) : ChatUiState()
    data class Success(val response: String, val reasoning: String? = null) : ChatUiState()
    data class Error(val message: String) : ChatUiState()
    data object ModelMissing : ChatUiState()
}

@HiltViewModel
class LlmChatViewModel @Inject constructor(
    private val llmProvider: LlmInferenceProvider,
    private val resumeRepository: ResumeRepository,
    private val candidateAgent: CandidateAgent
) : ViewModel() {

    private val _uiState = MutableStateFlow<ChatUiState>(ChatUiState.Idle)
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    fun checkModelAvailability() {
        if (!llmProvider.isModelAvailable()) {
            _uiState.value = ChatUiState.ModelMissing
        } else {
            _uiState.value = ChatUiState.Idle
        }
    }

    fun analyzeCandidateFit(resumeId: Long, roleDescription: String) {
        viewModelScope.launch {
            try {
                _uiState.value = ChatUiState.Loading
                
                val resume = resumeRepository.getResume(resumeId)
                if (resume == null) {
                    _uiState.value = ChatUiState.Error("Resume not found")
                    return@launch
                }

                if (!llmProvider.isModelAvailable()) {
                    _uiState.value = ChatUiState.ModelMissing
                    return@launch
                }

                val startTime = System.currentTimeMillis()
                
                // Use the agentic workflow
                candidateAgent.evaluateCandidate(resume, roleDescription).collect { step ->
                    when (step) {
                        is AgentStep.Thinking -> {
                            _uiState.value = ChatUiState.AgenticLoading(step.message)
                        }
                        is AgentStep.Processing -> {
                            _uiState.value = ChatUiState.AgenticLoading(step.message)
                        }
                        is AgentStep.FinalResult -> {
                            val endTime = System.currentTimeMillis()
                            val durationSeconds = (endTime - startTime) / 1000.0
                            android.util.Log.d("EdgeScoutGen", "BENCHMARK_AGENT: Agentic analysis took $durationSeconds seconds")
                            
                            _uiState.value = ChatUiState.Success(
                                response = step.content,
                                reasoning = step.reasoning
                            )
                        }
                        is AgentStep.Error -> {
                            _uiState.value = ChatUiState.Error(step.message)
                        }
                    }
                }

            } catch (e: Throwable) {
                Timber.e(e, "Agentic Analysis failed")
                _uiState.value = ChatUiState.Error("Analysis failed: ${e.message ?: "Unknown error"}. Ensure device has enough RAM.")
            }
        }
    }
}
