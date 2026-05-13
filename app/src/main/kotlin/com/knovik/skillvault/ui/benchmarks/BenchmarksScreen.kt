package com.knovik.skillvault.ui.benchmarks

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Empirical Benchmarks") },
                actions = {
                    IconButton(onClick = { viewModel.runAutoBenchmark() }, enabled = !isBenchmarking) {
                        Icon(Icons.Default.PlayArrow, contentDescription = "Run Suite", tint = if (isBenchmarking) Color.Gray else MaterialTheme.colorScheme.primary)
                    }
                    IconButton(onClick = { viewModel.loadMetrics() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                    IconButton(onClick = { viewModel.clearMetrics() }) {
                        Icon(Icons.Default.Delete, contentDescription = "Clear Data")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            if (isBenchmarking) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp))
            }
            // Summary Card
            SummaryCard(summary)

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Recent Operations",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Metrics List
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
                        style = MaterialTheme.typography.labelExtraSmall,
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
