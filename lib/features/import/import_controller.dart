import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/providers.dart';
import '../../data/importer/csv_importer.dart';
import '../../data/repository/resume_repository.dart';
import '../../domain/ingestion/embedding_ingestion_service.dart';
import '../../domain/ingestion/folder_import_service.dart';
import '../../domain/llm/llm_provider.dart';

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
  ImportController(
    this._repo,
    this._ingestion,
    this._folderImport,
    this._llm,
    this._ref,
  ) : super(const ImportIdle());

  final ResumeRepository _repo;
  final EmbeddingIngestionService _ingestion;
  final FolderImportService _folderImport;
  final LlmProvider _llm;
  final Ref _ref;

  /// Folder import needs a real OS folder picker — only reliable on
  /// Android (SAF) and macOS (NSOpenPanel) today. iOS's sandboxed file
  /// picker doesn't expose a clean folder-selection flow, so the entry
  /// point is hidden there (see import_screen.dart); this check is a
  /// defensive backstop in case the method is ever reached another way.
  static bool get isFolderImportSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isMacOS);

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

  Future<void> importFromFolder(String folderPath) async {
    if (!isFolderImportSupported) {
      state = const ImportError(
        'Folder import is not available on this platform yet.',
      );
      return;
    }
    if (!_llm.isModelAvailable) {
      state = const ImportError(
        'Folder import needs the on-device AI model to read resume fields. '
        'Download it from Settings & Models first.',
      );
      return;
    }

    state = const ImportLoading('Scanning folder…');
    try {
      final result = await _folderImport.importFolder(
        folderPath,
        onProgress: (done, total) {
          state = ImportLoading(
            'Processing $done of $total resumes…',
            progress: total == 0 ? null : done / total,
          );
        },
      );

      if (result.imported == 0 && result.skipped.isEmpty) {
        state = const ImportError('No PDF or DOCX files found in that folder.');
        return;
      }

      if (result.imported > 0) {
        state = ImportLoading('Indexing ${result.imported} resumes on-device…');
        final total = result.imported;
        await _ingestion.embedAllPending(onProgress: (done, _) {
          state = ImportLoading(
            'Indexing $done of $total resumes on-device…',
            progress: total == 0 ? null : done / total,
          );
        });
        _ref.read(libraryRevisionProvider.notifier).state++;
      }

      state = ImportSuccess(_summarize(result));
    } catch (e) {
      state = ImportError('Could not import folder: $e');
    }
  }

  String _summarize(FolderImportResult result) {
    final parts = <String>['${result.imported} imported'];
    final problems = result.problems;
    if (problems.isNotEmpty) {
      final counts = <FolderImportSkipReason, int>{};
      for (final p in problems) {
        counts[p.reason] = (counts[p.reason] ?? 0) + 1;
      }
      final reasons = counts.entries
          .map((e) => '${e.value} ${_reasonLabel(e.key)}')
          .join(', ');
      parts.add('${problems.length} skipped ($reasons)');
    }
    if (result.alreadyImported > 0) {
      parts.add('${result.alreadyImported} already imported');
    }
    return '${parts.join(', ')}.';
  }

  String _reasonLabel(FolderImportSkipReason reason) => switch (reason) {
        FolderImportSkipReason.unreadable => 'unreadable',
        FolderImportSkipReason.noExtractableText => 'no extractable text',
        FolderImportSkipReason.aiExtractionFailed => 'AI extraction failed',
        FolderImportSkipReason.alreadyImported => 'already imported',
      };

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
    ref.watch(folderImportServiceProvider),
    ref.watch(llmProviderProvider),
    ref,
  );
});
