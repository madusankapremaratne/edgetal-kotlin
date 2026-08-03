import '../local/local_database.dart';
import '../models/performance_metric.dart';
import '../models/resource_sample.dart';
import '../models/resume.dart';
import '../models/resume_embedding.dart';
import '../models/search_query.dart';

/// Single seam over the local store. Feature/ViewModel code only ever talks to
/// this repository — the persistence backend (currently JSON files, later
/// ObjectBox) stays an implementation detail.
class ResumeRepository {
  ResumeRepository(this._db);

  final LocalDatabase _db;

  // ---- Resumes ------------------------------------------------------------

  Future<int> insertOrUpdateResume(Resume resume) async {
    resume.updatedAt = DateTime.now().millisecondsSinceEpoch;
    if (resume.id == 0) {
      resume.id = _db.nextResumeId();
      _db.resumes.add(resume);
    } else {
      final i = _db.resumes.indexWhere((r) => r.id == resume.id);
      if (i >= 0) {
        _db.resumes[i] = resume;
      } else {
        _db.resumes.add(resume);
      }
    }
    await _db.persistResumes();
    return resume.id;
  }

  Future<Resume?> getResume(int id) async {
    final matches = _db.resumes.where((r) => r.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<Resume?> getResumeByExternalId(String resumeId) async {
    final matches = _db.resumes.where((r) => r.resumeId == resumeId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<List<Resume>> getAllResumes({bool sortByNewest = true}) async {
    final list = List<Resume>.from(_db.resumes);
    list.sort((a, b) => sortByNewest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<int> getResumeCount() async => _db.resumes.length;

  Future<List<Resume>> getUnembeddedResumes({int limit = 100}) async {
    return _db.resumes.where((r) => !r.isEmbedded).take(limit).toList();
  }

  Future<void> markResumeAsEmbedded(int resumeId, {bool success = true}) async {
    final r = await getResume(resumeId);
    if (r == null) return;
    r
      ..isEmbedded = success
      ..embeddedAt = DateTime.now().millisecondsSinceEpoch
      ..processingStatus = success ? 'completed' : 'failed'
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.persistResumes();
  }

  Future<void> deleteResume(int resumeId) async {
    _db.embeddings.removeWhere((e) => e.resumeId == resumeId);
    _db.resumes.removeWhere((r) => r.id == resumeId);
    await _db.persistResumes();
    await _db.persistEmbeddings();
  }

  Future<List<Resume>> searchResumesByKeyword(String keyword) async {
    final k = keyword.toLowerCase();
    return _db.resumes
        .where((r) =>
            r.fullName.toLowerCase().contains(k) ||
            r.skills.toLowerCase().contains(k) ||
            r.experience.toLowerCase().contains(k) ||
            r.summary.toLowerCase().contains(k))
        .toList();
  }

  // ---- Embeddings ---------------------------------------------------------

  Future<int> insertEmbedding(ResumeEmbedding embedding) async {
    embedding.id = _db.nextEmbeddingId();
    _db.embeddings.add(embedding);
    await _db.persistEmbeddings();
    return embedding.id;
  }

  Future<void> insertEmbeddingsBatch(List<ResumeEmbedding> embeddings) async {
    for (final e in embeddings) {
      e.id = _db.nextEmbeddingId();
      _db.embeddings.add(e);
    }
    await _db.persistEmbeddings();
  }

  Future<List<ResumeEmbedding>> getEmbeddingsForResume(int resumeId) async {
    return _db.embeddings.where((e) => e.resumeId == resumeId).toList();
  }

  Future<List<ResumeEmbedding>> getAllEmbeddings({int limit = 10000}) async {
    return _db.embeddings.take(limit).toList();
  }

  Future<int> getEmbeddingCount() async => _db.embeddings.length;

  Future<void> deleteEmbeddingsForResume(int resumeId) async {
    _db.embeddings.removeWhere((e) => e.resumeId == resumeId);
    await _db.persistEmbeddings();
  }

  // ---- Analytics ----------------------------------------------------------

  Future<void> recordSearchQuery(SearchQuery query) async {
    if (query.id == 0) {
      query.id = _db.nextQueryId();
      _db.searchQueries.add(query);
    } else {
      final i = _db.searchQueries.indexWhere((q) => q.id == query.id);
      if (i >= 0) _db.searchQueries[i] = query;
    }
    await _db.persistQueries();
  }

  Future<List<SearchQuery>> getSearchHistory({int limit = 50}) async {
    final list = List<SearchQuery>.from(_db.searchQueries);
    list.sort((a, b) => b.executedAt.compareTo(a.executedAt));
    return list.take(limit).toList();
  }

  Future<void> recordMetric(PerformanceMetric metric) async {
    metric.id = _db.nextMetricId();
    _db.metrics.add(metric);
    await _db.persistMetrics();
  }

  Future<List<PerformanceMetric>> getAllPerformanceMetrics() async =>
      List<PerformanceMetric>.from(_db.metrics);

  Future<void> clearPerformanceMetrics() async {
    _db.metrics.clear();
    await _db.persistMetrics();
  }

  Future<void> recordResourceSample(ResourceSample sample) async {
    sample.id = _db.nextResourceSampleId();
    _db.resourceSamples.add(sample);
    await _db.persistResourceSamples();
  }

  Future<List<ResourceSample>> getAllResourceSamples() async =>
      List<ResourceSample>.from(_db.resourceSamples);

  Future<void> clearResourceSamples() async {
    _db.resourceSamples.clear();
    await _db.persistResourceSamples();
  }

  Future<void> clearAllData() async {
    _db.embeddings.clear();
    _db.resumes.clear();
    _db.searchQueries.clear();
    await _db.persistResumes();
    await _db.persistEmbeddings();
    await _db.persistQueries();
  }
}
