package com.knovik.skillvault.ui.model_manager

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.knovik.skillvault.domain.llm.ModelDownloadManager
import com.knovik.skillvault.domain.llm.ModelDownloadManager.DownloadState
import java.util.Locale

/**
 * Lets users download, inspect and delete the on-device LLM model without adb.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModelManagerScreen(
    viewModel: ModelManagerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var customUrl by remember { mutableStateOf(ModelDownloadManager.LLM_MODEL_DEFAULT_URL) }
    var accessToken by remember { mutableStateOf("") }
    var showAdvanced by remember { mutableStateOf(false) }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { viewModel.refreshStatus() }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("Delete model?") },
            text = {
                Text(
                    "This frees ${formatBytes(uiState.installedSizeBytes)} of storage. " +
                        "AI analysis will be unavailable until the model is downloaded again."
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteModel()
                        showDeleteConfirm = false
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) { Text("Cancel") }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("AI Models") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Embedder status — bundled with the app, always available
            ModelStatusCard(
                title = "Text Embedder (Semantic Search)",
                subtitle = "MobileNet v3 · bundled with the app",
                installed = true
            )

            // LLM status + download
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = if (uiState.isModelInstalled) {
                                Icons.Filled.CheckCircle
                            } else {
                                Icons.Filled.Warning
                            },
                            contentDescription = null,
                            tint = if (uiState.isModelInstalled) {
                                MaterialTheme.colorScheme.primary
                            } else {
                                MaterialTheme.colorScheme.error
                            }
                        )
                        Column {
                            Text(
                                ModelDownloadManager.LLM_MODEL_DISPLAY_NAME,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                if (uiState.isModelInstalled) {
                                    "Installed · ${formatBytes(uiState.installedSizeBytes)}"
                                } else {
                                    "Not installed · powers AI Candidate Analysis"
                                },
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    when (val state = uiState.downloadState) {
                        is DownloadState.Downloading -> {
                            DownloadProgressSection(
                                state = state,
                                onCancel = { viewModel.cancelDownload() }
                            )
                        }
                        is DownloadState.Failed -> {
                            Text(
                                state.message,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.error
                            )
                            if (!uiState.isModelInstalled) {
                                DownloadButton(uiState, customUrl, accessToken, viewModel)
                            }
                        }
                        else -> {
                            if (!uiState.isModelInstalled) {
                                Text(
                                    "Download once over Wi-Fi (~1.3 GB). Everything runs " +
                                        "on-device afterwards — no data leaves your phone.",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                DownloadButton(uiState, customUrl, accessToken, viewModel)
                            }
                        }
                    }

                    if (uiState.isModelInstalled) {
                        OutlinedButton(
                            onClick = { showDeleteConfirm = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Icon(Icons.Filled.Delete, contentDescription = null)
                            Spacer(Modifier.width(8.dp))
                            Text("Delete Model")
                        }
                    }
                }
            }

            // Advanced: custom URL / gated repos
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            "Advanced: custom source",
                            style = MaterialTheme.typography.titleSmall,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(onClick = { showAdvanced = !showAdvanced }) {
                            Icon(
                                if (showAdvanced) Icons.Filled.KeyboardArrowUp
                                else Icons.Filled.KeyboardArrowDown,
                                contentDescription = if (showAdvanced) "Collapse" else "Expand"
                            )
                        }
                    }
                    if (showAdvanced) {
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text(
                                "Download from any direct URL, e.g. a Hugging Face " +
                                    "\"resolve\" link. For gated repos (official Gemma), " +
                                    "accept the license on huggingface.co and paste a " +
                                    "read access token below.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            OutlinedTextField(
                                value = customUrl,
                                onValueChange = { customUrl = it },
                                label = { Text("Model URL") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true
                            )
                            OutlinedTextField(
                                value = accessToken,
                                onValueChange = { accessToken = it },
                                label = { Text("Hugging Face token (optional)") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true,
                                visualTransformation = PasswordVisualTransformation()
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DownloadButton(
    uiState: ModelManagerUiState,
    customUrl: String,
    accessToken: String,
    viewModel: ModelManagerViewModel
) {
    Button(
        onClick = { viewModel.startDownload(customUrl, accessToken) },
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            if (uiState.partialSizeBytes > 0) {
                "Resume Download (${formatBytes(uiState.partialSizeBytes)} done)"
            } else {
                "Download Model (~1.3 GB)"
            }
        )
    }
}

@Composable
private fun DownloadProgressSection(
    state: DownloadState.Downloading,
    onCancel: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (state.totalBytes > 0) {
            LinearProgressIndicator(
                progress = state.bytesDownloaded.toFloat() / state.totalBytes,
                modifier = Modifier.fillMaxWidth()
            )
            Text(
                "${formatBytes(state.bytesDownloaded)} of ${formatBytes(state.totalBytes)} " +
                    "(${state.percentage}%) · ${formatBytes(state.bytesPerSecond)}/s",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else {
            LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            Text(
                "${formatBytes(state.bytesDownloaded)} downloaded · " +
                    "${formatBytes(state.bytesPerSecond)}/s",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        OutlinedButton(onClick = onCancel, modifier = Modifier.fillMaxWidth()) {
            Text("Pause")
        }
    }
}

@Composable
private fun ModelStatusCard(title: String, subtitle: String, installed: Boolean) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = null,
                tint = if (installed) MaterialTheme.colorScheme.primary
                else MaterialTheme.colorScheme.error
            )
            Column {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

private fun formatBytes(bytes: Long): String = when {
    bytes >= 1_000_000_000 -> String.format(Locale.US, "%.2f GB", bytes / 1_000_000_000.0)
    bytes >= 1_000_000 -> String.format(Locale.US, "%.1f MB", bytes / 1_000_000.0)
    bytes >= 1_000 -> String.format(Locale.US, "%.0f KB", bytes / 1_000.0)
    else -> "$bytes B"
}
