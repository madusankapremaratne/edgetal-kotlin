package com.knovik.skillvault.ui.benchmarks

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.knovik.skillvault.data.entity.PerformanceMetric
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BenchmarksScreen(
    viewModel: BenchmarksViewModel = hiltViewModel()
) {
    val metrics by viewModel.metrics.collectAsState()
    val summary by viewModel.summary.collectAsState()
    val isBenchmarking by viewModel.isBenchmarking.collectAsState()
    val clipboardManager = LocalClipboardManager.current
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    
    var showTable by remember { mutableStateOf(true) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("Empirical Benchmarks") },
                actions = {
                    IconButton(onClick = { showTable = !showTable }) {
                        Icon(
                            if (showTable) Icons.Default.List else Icons.Default.Info, 
                            contentDescription = "Toggle View"
                        )
                    }
                    IconButton(onClick = { 
                        val csv = viewModel.getExportCsvContent()
                        clipboardManager.setText(AnnotatedString(csv))
                        scope.launch {
                            snackbarHostState.showSnackbar("CSV copied to clipboard")
                        }
                    }) {
                        Icon(Icons.Default.Share, contentDescription = "Export CSV")
                    }
                    IconButton(onClick = { viewModel.runAutoBenchmark() }, enabled = !isBenchmarking) {
                        Icon(Icons.Default.PlayArrow, contentDescription = "Run Suite", tint = if (isBenchmarking) Color.Gray else MaterialTheme.colorScheme.primary)
                    }
                    IconButton(onClick = { viewModel.loadMetrics() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                    IconButton(onClick = { viewModel.clearMetrics() }) {
                        Icon(Icons.Default.Delete, contentDescription = "Clear Data")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (isBenchmarking) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            }
            
            if (showTable) {
                BenchmarkTableView(metrics)
            } else {
                Column(modifier = Modifier.padding(16.dp)) {
                    SummaryCard(summary)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Recent Operations",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(metrics.reversed()) { metric ->
                            MetricItem(metric)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun BenchmarkTableView(metrics: List<PerformanceMetric>) {
    val scrollState = rememberScrollState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .horizontalScroll(scrollState)
            .padding(8.dp)
    ) {
        // Table Header
        Row(
            modifier = Modifier
                .background(MaterialTheme.colorScheme.secondaryContainer)
                .border(1.dp, MaterialTheme.colorScheme.outline)
        ) {
            TableCell("Type", weight = 0.15f, isHeader = true)
            TableCell("Operation Name", weight = 0.35f, isHeader = true)
            TableCell("Duration", weight = 0.15f, isHeader = true)
            TableCell("R/E", weight = 0.15f, isHeader = true)
            TableCell("Time", weight = 0.2f, isHeader = true)
        }

        // Table Rows
        LazyColumn(modifier = Modifier.fillMaxWidth()) {
            items(metrics.reversed()) { metric ->
                val dateFormat = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(0.5.dp, MaterialTheme.colorScheme.outlineVariant)
                ) {
                    TableCell(metric.operationType, weight = 0.15f)
                    TableCell(metric.operationName, weight = 0.35f)
                    TableCell("${metric.durationMs}ms", weight = 0.15f)
                    TableCell("${metric.resumeCount}/${metric.embeddingCount}", weight = 0.15f)
                    TableCell(dateFormat.format(Date(metric.timestamp)), weight = 0.2f)
                }
            }
        }
    }
}

@Composable
fun RowScope.TableCell(
    text: String,
    weight: Float,
    isHeader: Boolean = false
) {
    Text(
        text = text,
        modifier = Modifier
            .weight(weight)
            .padding(8.dp)
            .widthIn(min = 100.dp),
        style = if (isHeader) MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold) 
                else MaterialTheme.typography.bodySmall,
        textAlign = TextAlign.Start,
        maxLines = 2
    )
}

@Composable
fun SummaryCard(summary: BenchmarkSummary) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Device: ${summary.deviceInfo}",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                SummaryStat("Ingestion", "${summary.avgIngestionMs.toInt()}ms")
                SummaryStat("Retrieval", "${summary.avgRetrievalMs.toInt()}ms")
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                SummaryStat("Reasoning", "${summary.avgReasoningMs.toInt()}ms")
                SummaryStat("Reformulate", "${summary.avgReformulationMs.toInt()}ms")
            }
        }
    }
}

@Composable
fun SummaryStat(label: String, value: String) {
    Column {
        Text(text = label, style = MaterialTheme.typography.labelSmall)
        Text(text = value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun MetricItem(metric: PerformanceMetric) {
    val dateFormat = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(12.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = metric.operationName,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${metric.operationType} | ${dateFormat.format(Date(metric.timestamp))}",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.Gray
                )
                if (metric.contextData.isNotBlank()) {
                    Text(
                        text = metric.contextData,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
            }
            
            Text(
                text = "${metric.durationMs} ms",
                style = MaterialTheme.typography.titleMedium,
                color = if (metric.durationMs > 1000) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
