import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/local_database.dart';
import '../data/repository/resume_repository.dart';
import '../domain/embedding/embedding_provider.dart';
import '../domain/embedding/native_embedding_provider.dart';
import '../domain/guide/in_app_guide_service.dart';
import '../domain/ingestion/embedding_ingestion_service.dart';
import '../domain/ingestion/folder_import_service.dart';
import '../domain/llm/candidate_agent.dart';
import '../domain/llm/inference_backend_preference.dart';
import '../domain/llm/llm_provider.dart';
import '../domain/llm/model_download_manager.dart';
import '../domain/llm/native_llm_provider.dart';
import '../domain/llm/resume_extraction_agent.dart';
import '../domain/llm/search_agent.dart';
import '../domain/monitor/performance_monitor.dart';
import '../domain/monitor/resource_profiler.dart';
import '../domain/search/vector_search_engine.dart';

/// Composition root. One place to see the whole dependency graph and to swap an
/// implementation (e.g. the persistence backend or the ML providers) for tests.

final localDatabaseProvider = Provider<LocalDatabase>((_) => LocalDatabase.instance);

final resumeRepositoryProvider = Provider<ResumeRepository>(
  (ref) => ResumeRepository(ref.watch(localDatabaseProvider)),
);

final performanceMonitorProvider = Provider<PerformanceMonitor>(
  (ref) => PerformanceMonitor(ref.watch(resumeRepositoryProvider)),
);

final resourceProfilerProvider = Provider<ResourceProfiler>((_) => ResourceProfiler());

final inferenceBackendPreferenceProvider =
    Provider<InferenceBackendPreference>((_) => InferenceBackendPreference());

final inAppGuideServiceProvider =
    Provider<InAppGuideService>((_) => InAppGuideService());

final embeddingProviderProvider = Provider<EmbeddingProvider>(
  (_) => NativeEmbeddingProvider(),
);

final vectorSearchEngineProvider = Provider<VectorSearchEngine>(
  (ref) => VectorSearchEngine(ref.watch(performanceMonitorProvider)),
);

final downloadManagerProvider = Provider<ModelDownloadManager>(
  (_) => ModelDownloadManager.instance,
);

final llmProviderProvider = Provider<LlmProvider>(
  (ref) => NativeLlmProvider(ref.watch(downloadManagerProvider)),
);

final searchAgentProvider = Provider<SearchAgent>(
  (ref) => SearchAgent(ref.watch(llmProviderProvider)),
);

final candidateAgentProvider = Provider<CandidateAgent>(
  (ref) => CandidateAgent(
    ref.watch(llmProviderProvider),
    ref.watch(performanceMonitorProvider),
  ),
);

final ingestionServiceProvider = Provider<EmbeddingIngestionService>(
  (ref) => EmbeddingIngestionService(
    ref.watch(resumeRepositoryProvider),
    ref.watch(embeddingProviderProvider),
    ref.watch(performanceMonitorProvider),
  ),
);

final resumeExtractionAgentProvider = Provider<ResumeExtractionAgent>(
  (ref) => ResumeExtractionAgent(ref.watch(llmProviderProvider)),
);

final folderImportServiceProvider = Provider<FolderImportService>(
  (ref) => FolderImportService(
    ref.watch(resumeRepositoryProvider),
    ref.watch(resumeExtractionAgentProvider),
  ),
);

/// Bumped whenever the resume/embedding collections change so screens that read
/// counts or lists can refresh.
final libraryRevisionProvider = StateProvider<int>((_) => 0);

/// Runs once at app start: if the stored embeddings were built by a different
/// embedder than the active one (e.g. offline fallback → on-device MediaPipe),
/// regenerates them so search stays consistent. Cached, so it never re-runs.
final startupReconcileProvider = FutureProvider<bool>((ref) async {
  final changed = await ref.read(ingestionServiceProvider).reindexIfStale();
  if (changed) ref.read(libraryRevisionProvider.notifier).state++;
  return changed;
});
