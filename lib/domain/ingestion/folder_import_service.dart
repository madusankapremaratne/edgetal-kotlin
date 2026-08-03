import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../data/importer/folder_importer.dart';
import '../../data/models/resume.dart';
import '../../data/repository/resume_repository.dart';
import '../llm/resume_extraction_agent.dart';

/// Why a given file didn't become a resume.
enum FolderImportSkipReason {
  alreadyImported,
  unreadable,
  noExtractableText,
  aiExtractionFailed,
}

class FolderImportSkip {
  const FolderImportSkip(this.path, this.reason);
  final String path;
  final FolderImportSkipReason reason;
}

class FolderImportResult {
  const FolderImportResult({required this.imported, required this.skipped});
  final int imported;
  final List<FolderImportSkip> skipped;

  int get alreadyImported => skipped
      .where((s) => s.reason == FolderImportSkipReason.alreadyImported)
      .length;

  /// Skips other than "already imported" — genuine problems worth surfacing.
  List<FolderImportSkip> get problems => skipped
      .where((s) => s.reason != FolderImportSkipReason.alreadyImported)
      .toList();
}

/// Orchestrates "for each resume file in a folder: extract text -> ask the
/// on-device LLM for structured fields -> store as a Resume". Runs files
/// strictly sequentially — the local LLM isn't built for concurrent calls,
/// and a large batch (50-500 files) would overload it otherwise.
///
/// Deliberately mirrors the CSV path's contract (produces the same [Resume]
/// objects, same repository calls) so [EmbeddingIngestionService] downstream
/// needs zero changes — it already embeds any unembedded resume regardless
/// of [Resume.fileFormat].
class FolderImportService {
  FolderImportService(this._repo, this._extractionAgent);

  final ResumeRepository _repo;
  final ResumeExtractionAgent _extractionAgent;

  Future<FolderImportResult> importFolder(
    String folderPath, {
    void Function(int done, int total)? onProgress,
  }) async {
    final files = FolderImporter.scan(folderPath);
    var imported = 0;
    final skipped = <FolderImportSkip>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final outcome = await _importOne(file);
      if (outcome == null) {
        imported++;
      } else {
        skipped.add(outcome);
      }
      onProgress?.call(i + 1, files.length);
    }

    return FolderImportResult(imported: imported, skipped: skipped);
  }

  /// Returns `null` on success (resume was imported), or a [FolderImportSkip]
  /// describing why the file was skipped.
  Future<FolderImportSkip?> _importOne(File file) async {
    final String resumeId;
    try {
      resumeId = await _hashId(file);
    } catch (e) {
      return FolderImportSkip(file.path, FolderImportSkipReason.unreadable);
    }

    // Check before doing any expensive extraction/LLM work — the whole point
    // of hashing first is that re-scanning a mostly-unchanged folder only
    // pays for the files that actually changed.
    final existing = await _repo.getResumeByExternalId(resumeId);
    if (existing != null) {
      return FolderImportSkip(file.path, FolderImportSkipReason.alreadyImported);
    }

    final String rawText;
    try {
      rawText = await FolderImporter.extractText(file);
    } on EmptyResumeTextException {
      return FolderImportSkip(file.path, FolderImportSkipReason.noExtractableText);
    } catch (_) {
      return FolderImportSkip(file.path, FolderImportSkipReason.unreadable);
    }

    ExtractedFields? fields;
    try {
      fields = await _extractionAgent.extractFields(rawText);
    } catch (_) {
      fields = null;
    }
    if (fields == null) {
      return FolderImportSkip(file.path, FolderImportSkipReason.aiExtractionFailed);
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'pdf';

    await _repo.insertOrUpdateResume(Resume(
      resumeId: resumeId,
      fullName: fields.fullName.isEmpty ? fileName : fields.fullName,
      email: fields.email,
      phoneNumber: fields.phone,
      rawText: rawText,
      summary: fields.summary,
      skills: fields.skills,
      experience: fields.experience,
      education: fields.education,
      certifications: fields.certifications,
      category: fields.category,
      sourceFile: fileName,
      fileFormat: ext,
    ));
    return null;
  }

  Future<String> _hashId(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return 'file_${digest.toString().substring(0, 16)}';
  }
}
