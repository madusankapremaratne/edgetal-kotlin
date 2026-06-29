import '../../data/models/resume.dart';
import '../../data/models/resume_embedding.dart';
import '../../data/repository/resume_repository.dart';
import '../embedding/embedding_provider.dart';
import '../monitor/performance_monitor.dart';

/// Generates and stores section-level embeddings for resumes. Ported from the
/// original `EmbeddingIngestionService` / worker, minus the Android Service
/// plumbing — here it's a plain async service driven from the Import flow.
class EmbeddingIngestionService {
  EmbeddingIngestionService(this._repository, this._embedder, this._monitor);

  final ResumeRepository _repository;
  final EmbeddingProvider _embedder;
  final PerformanceMonitor _monitor;

  static const _sectionKeys = ['summary', 'skills', 'experience', 'education', 'certifications'];

  /// Embeds every resume that hasn't been embedded yet. [onProgress] reports
  /// `(done, total)`.
  Future<int> embedAllPending({
    void Function(int done, int total)? onProgress,
  }) async {
    await _embedder.initialize();
    final pending = await _repository.getUnembeddedResumes(limit: 100000);
    for (var i = 0; i < pending.length; i++) {
      await embedResume(pending[i].id);
      onProgress?.call(i + 1, pending.length);
    }
    return pending.length;
  }

  Future<void> embedResume(int resumeId) async {
    final resume = await _repository.getResume(resumeId);
    if (resume == null) return;
    try {
      await _repository.insertOrUpdateResume(
        resume.copyWith(processingStatus: 'processing'),
      );
      // Replace any stale embeddings so re-running is idempotent.
      await _repository.deleteEmbeddingsForResume(resumeId);
      final embeddings = await _generate(resume);
      await _repository.insertEmbeddingsBatch(embeddings);
      await _repository.markResumeAsEmbedded(resumeId, success: true);
    } catch (e) {
      await _repository.insertOrUpdateResume(
        resume.copyWith(processingStatus: 'failed', errorMessage: e.toString()),
      );
    }
  }

  Future<List<ResumeEmbedding>> _generate(Resume resume) async {
    final stopwatch = Stopwatch()..start();
    final embeddings = <ResumeEmbedding>[];
    var segmentId = 0;

    final sections = <String, String>{
      'summary': resume.summary,
      'skills': resume.skills,
      'experience': resume.experience,
      'education': resume.education,
      'certifications': resume.certifications,
    };

    for (final type in _sectionKeys) {
      final text = sections[type] ?? '';
      if (text.isEmpty) continue;
      for (final seg in _embedder.segmentText(text, type)) {
        // Prepend section type for better semantic context (as in the original).
        final vector = await _embedder.embedText('$type: ${seg.text}');
        embeddings.add(ResumeEmbedding(
          resumeId: resume.id,
          segmentId: '${type}_$segmentId',
          segmentType: type,
          segmentText: seg.text,
          embedding: vector,
          embeddingModel: _embedder.backendLabel,
          embeddingDimension: _embedder.dimension,
        ));
        segmentId++;
      }
    }

    stopwatch.stop();
    _monitor.recordLatency(
      type: 'ingestion',
      name: 'Embedding Ingestion',
      durationMs: stopwatch.elapsedMilliseconds,
      embeddingCount: embeddings.length,
    );
    return embeddings;
  }
}
