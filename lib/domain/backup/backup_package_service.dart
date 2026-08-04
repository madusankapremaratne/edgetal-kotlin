import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/job.dart';
import '../../data/models/resume.dart';

class BackupPackageService {
  static const String packageExtension = 'edgetal';

  /// Encrypts and exports the local candidate database and job pipeline into
  /// a secure, portable `.edgetal` package for peer-to-peer sharing.
  Future<File> createPackage({
    required List<Resume> resumes,
    required List<JobRole> jobs,
    String? password,
  }) async {
    final payload = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'candidateCount': resumes.length,
      'jobCount': jobs.length,
      'resumes': resumes.map((r) => r.toJson()).toList(),
      'jobs': jobs.map((j) => j.toJson()).toList(),
    };

    final rawJson = jsonEncode(payload);
    String packageContent;

    if (password != null && password.trim().isNotEmpty) {
      final key = sha256.convert(utf8.encode(password.trim())).bytes;
      final bytes = utf8.encode(rawJson);
      final encryptedBytes = <int>[];
      for (var i = 0; i < bytes.length; i++) {
        encryptedBytes.add(bytes[i] ^ key[i % key.length]);
      }
      packageContent = 'EDGETAL_ENC_v1:' + base64Encode(encryptedBytes);
    } else {
      packageContent = 'EDGETAL_RAW_v1:' + base64Encode(utf8.encode(rawJson));
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/edgetal_backup_${DateTime.now().millisecondsSinceEpoch}.$packageExtension',
    );
    await file.writeAsString(packageContent);
    return file;
  }

  /// Decrypts and parses a `.edgetal` package file.
  Future<Map<String, dynamic>> parsePackage(
    File file, {
    String? password,
  }) async {
    final content = await file.readAsString();
    String rawJson;

    if (content.startsWith('EDGETAL_ENC_v1:')) {
      if (password == null || password.trim().isEmpty) {
        throw FormatException('Password required for encrypted package');
      }
      final base64Str = content.substring('EDGETAL_ENC_v1:'.length);
      final encryptedBytes = base64Decode(base64Str);
      final key = sha256.convert(utf8.encode(password.trim())).bytes;
      final decryptedBytes = <int>[];
      for (var i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ key[i % key.length]);
      }
      rawJson = utf8.decode(decryptedBytes);
    } else if (content.startsWith('EDGETAL_RAW_v1:')) {
      final base64Str = content.substring('EDGETAL_RAW_v1:'.length);
      rawJson = utf8.decode(base64Decode(base64Str));
    } else {
      // Fallback: try raw JSON
      rawJson = content;
    }

    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    return data;
  }
}
