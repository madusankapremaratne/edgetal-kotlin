package com.knovik.skillvault.ui.model_manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.knovik.skillvault.domain.llm.ModelDownloadManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ModelManagerUiState(
    val isModelInstalled: Boolean = false,
    val installedSizeBytes: Long = 0L,
    val partialSizeBytes: Long = 0L,
    val downloadState: ModelDownloadManager.DownloadState = ModelDownloadManager.DownloadState.Idle
)

@HiltViewModel
class ModelManagerViewModel @Inject constructor(
    private val downloadManager: ModelDownloadManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(ModelManagerUiState())
    val uiState: StateFlow<ModelManagerUiState> = _uiState.asStateFlow()

    init {
        refreshStatus()
        viewModelScope.launch {
            downloadManager.downloadState.collect { state ->
                _uiState.value = _uiState.value.copy(
                    downloadState = state,
                    isModelInstalled = downloadManager.isModelInstalled(),
                    installedSizeBytes = downloadManager.installedModelSizeBytes(),
                    partialSizeBytes = downloadManager.partialDownloadSizeBytes()
                )
            }
        }
    }

    fun refreshStatus() {
        _uiState.value = _uiState.value.copy(
            isModelInstalled = downloadManager.isModelInstalled(),
            installedSizeBytes = downloadManager.installedModelSizeBytes(),
            partialSizeBytes = downloadManager.partialDownloadSizeBytes()
        )
    }

    fun startDownload(url: String, accessToken: String) {
        downloadManager.startDownload(
            url = url.ifBlank { ModelDownloadManager.LLM_MODEL_DEFAULT_URL },
            accessToken = accessToken.ifBlank { null }
        )
    }

    fun cancelDownload() = downloadManager.cancelDownload()

    fun deleteModel() {
        downloadManager.deleteModel()
        refreshStatus()
    }
}
