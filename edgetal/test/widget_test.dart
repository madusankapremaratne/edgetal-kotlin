import 'package:flutter_test/flutter_test.dart';

import 'package:edgetal/data/importer/csv_importer.dart';
import 'package:edgetal/data/models/resume_embedding.dart';
import 'package:edgetal/domain/embedding/hashing_embedding_provider.dart';
import 'package:edgetal/domain/monitor/performance_monitor.dart';
import 'package:edgetal/domain/search/vector_search_engine.dart';

class _NoopMonitor implements PerformanceMonitor {
  @override
  String get deviceInfo => 'test';
  @override
  void recordLatency({
    required String type,
    required String name,
    required int durationMs,
    int resumeCount = 0,
    int embeddingCount = 0,
    double precision = 0,
    String contextData = '',
  }) {}
  @override
  noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('CSV importer detects the Kaggle format', () {
    const csv = 'name,email,skills,category\n'
        'Alice,a@example.eu,"Python, Kafka",Engineering\n';
    final result = CsvImporter.import(csv);
    expect(result.format, CsvFormat.kaggle);
    expect(result.resumes.single.fullName, 'Alice');
    expect(result.resumes.single.skillList, contains('Kafka'));
  });

  test('Vector search ranks the lexically closest segment first', () async {
    final embedder = HashingEmbeddingProvider();
    final engine = VectorSearchEngine(_NoopMonitor());

    final candidates = <ResumeEmbedding>[];
    final texts = {
      1: 'skills: kotlin spring boot kafka kubernetes backend',
      2: 'skills: figma accessibility design prototyping research',
      3: 'skills: recruiting sourcing interviewing employer branding',
    };
    for (final entry in texts.entries) {
      candidates.add(ResumeEmbedding(
        resumeId: entry.key,
        segmentType: 'skills',
        segmentText: entry.value,
        embedding: await embedder.embedText(entry.value),
      ));
    }

    final query = await embedder.embedText('backend engineer with kafka');
    final results =
        await engine.search(query, candidates, similarityThreshold: 0);

    expect(results.first.resumeId, 1);
  });
}
