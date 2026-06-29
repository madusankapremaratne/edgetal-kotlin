import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/importer/csv_importer.dart';
import '../data/local/local_database.dart';
import '../data/repository/resume_repository.dart';
import '../domain/embedding/hashing_embedding_provider.dart';
import '../domain/ingestion/embedding_ingestion_service.dart';
import '../domain/monitor/performance_monitor.dart';

/// One-time app start-up: open the local store and, on first run, seed a small
/// set of sample European candidates so the product is immediately explorable.
class Bootstrap {
  static const _seededKey = 'edgetal_seeded_v1';

  static Future<void> run() async {
    final db = LocalDatabase.instance;
    await db.init();

    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_seededKey) ?? false;
    if (alreadySeeded || db.resumes.isNotEmpty) return;

    try {
      final csv =
          await rootBundle.loadString('assets/data/sample_resumes.csv');
      final repo = ResumeRepository(db);
      final result = CsvImporter.import(csv, sourceFile: 'sample_resumes.csv');
      for (final resume in result.resumes) {
        await repo.insertOrUpdateResume(resume);
      }

      // Seed embeddings with the offline embedder so first run never depends on
      // the native layer being wired in.
      final ingestion = EmbeddingIngestionService(
        repo,
        HashingEmbeddingProvider(),
        PerformanceMonitor(repo),
      );
      await ingestion.embedAllPending();

      await prefs.setBool(_seededKey, true);
    } catch (_) {
      // Seeding is best-effort; the app works fine starting empty.
    }
  }
}
