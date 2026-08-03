import 'dart:io';
import 'dart:typed_data';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Thrown when a resume file's text can't be extracted at all (corrupt file,
/// unsupported encoding, etc).
class UnreadableResumeFileException implements Exception {
  UnreadableResumeFileException(this.path, this.cause);
  final String path;
  final Object cause;

  @override
  String toString() => 'Could not read $path: $cause';
}

/// Thrown when extraction succeeds but yields effectively no text — the
/// common case being a scanned-image PDF with no embedded text layer.
class EmptyResumeTextException implements Exception {
  EmptyResumeTextException(this.path);
  final String path;

  @override
  String toString() => 'No extractable text in $path (likely a scanned image)';
}

/// Scans a folder for resume files and extracts raw text from each.
///
/// v1 only looks at top-level files (no recursive subfolder walk) and only
/// supports PDF/DOCX — matching the "point me at a folder of resumes" mental
/// model most recruiters have.
class FolderImporter {
  FolderImporter._();

  static const supportedExtensions = {'pdf', 'docx'};

  /// Lists top-level PDF/DOCX files in [folderPath], sorted by name for
  /// deterministic progress reporting.
  static List<File> scan(String folderPath) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return [];
    final files = dir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => supportedExtensions.contains(_extensionOf(f.path)))
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Extracts raw text from a single resume [file]. Throws
  /// [UnreadableResumeFileException] on a corrupt/unsupported file, or
  /// [EmptyResumeTextException] if extraction succeeds but yields no usable
  /// text.
  static Future<String> extractText(File file) async {
    final ext = _extensionOf(file.path);
    late final String text;
    try {
      final bytes = await file.readAsBytes();
      text = switch (ext) {
        'pdf' => _extractPdfText(bytes),
        'docx' => docxToText(bytes),
        _ => throw UnsupportedError('Unsupported extension: $ext'),
      };
    } catch (e) {
      throw UnreadableResumeFileException(file.path, e);
    }

    final trimmed = text.trim();
    if (trimmed.length < 20) {
      throw EmptyResumeTextException(file.path);
    }
    return trimmed;
  }

  static String _extractPdfText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
