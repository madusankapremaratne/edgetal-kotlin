import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/performance_metric.dart';
import '../models/resource_sample.dart';
import '../models/resume.dart';
import '../models/resume_embedding.dart';
import '../models/search_query.dart';

/// Lightweight on-device store.
///
/// Holds entities in memory and persists each collection to a JSON file in the
/// app's private documents directory. This keeps the whole app runnable with no
/// native build step or code generation, while isolating persistence behind a
/// single seam — swapping in ObjectBox (with its HNSW vector index) later only
/// touches this class and the repository, not the feature code.
class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  final List<Resume> resumes = [];
  final List<ResumeEmbedding> embeddings = [];
  final List<SearchQuery> searchQueries = [];
  final List<PerformanceMetric> metrics = [];
  final List<ResourceSample> resourceSamples = [];

  int _resumeSeq = 1;
  int _embeddingSeq = 1;
  int _querySeq = 1;
  int _metricSeq = 1;
  int _resourceSampleSeq = 1;

  bool _initialized = false;
  Directory? _dir;

  int nextResumeId() => _resumeSeq++;
  int nextEmbeddingId() => _embeddingSeq++;
  int nextQueryId() => _querySeq++;
  int nextMetricId() => _metricSeq++;
  int nextResourceSampleId() => _resourceSampleSeq++;

  Future<void> init() async {
    if (_initialized) return;
    _dir = await getApplicationDocumentsDirectory();
    await _load();
    _initialized = true;
  }

  File _file(String name) => File('${_dir!.path}/edgetal_$name.json');

  Future<void> _load() async {
    resumes
      ..clear()
      ..addAll(await _readList('resumes', Resume.fromJson));
    embeddings
      ..clear()
      ..addAll(await _readList('embeddings', ResumeEmbedding.fromJson));
    searchQueries
      ..clear()
      ..addAll(await _readList('queries', SearchQuery.fromJson));
    metrics
      ..clear()
      ..addAll(await _readList('metrics', PerformanceMetric.fromJson));
    resourceSamples
      ..clear()
      ..addAll(await _readList('resource_samples', ResourceSample.fromJson));

    _resumeSeq = _maxId(resumes.map((e) => e.id)) + 1;
    _embeddingSeq = _maxId(embeddings.map((e) => e.id)) + 1;
    _querySeq = _maxId(searchQueries.map((e) => e.id)) + 1;
    _metricSeq = _maxId(metrics.map((e) => e.id)) + 1;
    _resourceSampleSeq = _maxId(resourceSamples.map((e) => e.id)) + 1;
  }

  int _maxId(Iterable<int> ids) =>
      ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);

  Future<List<T>> _readList<T>(
    String name,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final file = _file(name);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (_) {
      return [];
    }
  }

  Future<void> persistResumes() =>
      _write('resumes', resumes.map((e) => e.toJson()).toList());
  Future<void> persistEmbeddings() =>
      _write('embeddings', embeddings.map((e) => e.toJson()).toList());
  Future<void> persistQueries() =>
      _write('queries', searchQueries.map((e) => e.toJson()).toList());
  Future<void> persistMetrics() =>
      _write('metrics', metrics.map((e) => e.toJson()).toList());
  Future<void> persistResourceSamples() => _write(
      'resource_samples', resourceSamples.map((e) => e.toJson()).toList());

  Future<void> _write(String name, List<Map<String, dynamic>> data) async {
    if (_dir == null) return;
    await _file(name).writeAsString(jsonEncode(data));
  }
}
