import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/providers.dart';
import '../../data/importer/csv_importer.dart';
import '../../data/repository/resume_repository.dart';
import '../../domain/ingestion/embedding_ingestion_service.dart';

sealed class ImportUiState {
  const ImportUiState();
}

class ImportIdle extends ImportUiState {
  const ImportIdle();
}

class ImportLoading extends ImportUiState {
  const ImportLoading(this.message, {this.progress});
  final String message;
  final double? progress;
}

class ImportSuccess extends ImportUiState {
  const ImportSuccess(this.message);
  final String message;
}

class ImportError extends ImportUiState {
  const ImportError(this.message);
  final String message;
}

class ImportController extends StateNotifier<ImportUiState> {
  ImportController(this._repo, this._ingestion, this._ref)
      : super(const ImportIdle());

  final ResumeRepository _repo;
  final EmbeddingIngestionService _ingestion;
  final Ref _ref;

  Future<void> importFromUrl(String url) async {
    final target = url.trim();
    if (!target.startsWith('http')) {
      state = const ImportError('Enter a valid http(s) URL.');
      return;
    }
    state = const ImportLoading('Downloading CSV…');
    try {
      final response = await http.get(Uri.parse(target));
      if (response.statusCode != 200) {
        state = ImportError('Download failed: HTTP ${response.statusCode}');
        return;
      }
      await _ingest(response.body, target.split('/').last);
    } catch (e) {
      state = ImportError('Could not import: $e');
    }
  }

  Future<void> importFromFile(String path) async {
    state = const ImportLoading('Reading file…');
    try {
      final content = await File(path).readAsString();
      await _ingest(content, path.split(Platform.pathSeparator).last);
    } catch (e) {
      state = ImportError('Could not read file: $e');
    }
  }

  Future<void> _ingest(String csv, String sourceFile) async {
    state = const ImportLoading('Parsing resumes…');
    final result = CsvImporter.import(csv, sourceFile: sourceFile);
    if (result.resumes.isEmpty) {
      state = const ImportError('No rows found. Check the CSV has a header row.');
      return;
    }
    for (final resume in result.resumes) {
      await _repo.insertOrUpdateResume(resume);
    }

    state = ImportLoading('Indexing ${result.resumes.length} resumes on-device…');
    final total = result.resumes.length;
    await _ingestion.embedAllPending(onProgress: (done, _) {
      state = ImportLoading(
        'Indexing $done of $total resumes on-device…',
        progress: total == 0 ? null : done / total,
      );
    });

    _ref.read(libraryRevisionProvider.notifier).state++;
    state = ImportSuccess(
      'Imported ${result.resumes.length} resumes '
      '(${_formatName(result.format)} format) and indexed them locally.',
    );
  }

  Future<void> generateEmbeddings() async {
    state = const ImportLoading('Re-indexing resumes on-device…');
    try {
      final count = await _ingestion.embedAllPending(onProgress: (done, total) {
        state = ImportLoading(
          'Indexing $done of $total resumes…',
          progress: total == 0 ? null : done / total,
        );
      });
      _ref.read(libraryRevisionProvider.notifier).state++;
      state = ImportSuccess(
        count == 0 ? 'All resumes already indexed.' : 'Indexed $count resumes.',
      );
    } catch (e) {
      state = ImportError('Indexing failed: $e');
    }
  }

  void reset() => state = const ImportIdle();

  String _formatName(CsvFormat f) => switch (f) {
        CsvFormat.kaggle => 'Kaggle',
        CsvFormat.extended => 'Extended',
        CsvFormat.custom => 'auto-detected',
      };
}

final importControllerProvider =
    StateNotifierProvider<ImportController, ImportUiState>((ref) {
  return ImportController(
    ref.watch(resumeRepositoryProvider),
    ref.watch(ingestionServiceProvider),
    ref,
  );
});
