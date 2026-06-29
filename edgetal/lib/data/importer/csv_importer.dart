import 'package:csv/csv.dart';

import '../models/resume.dart';

enum CsvFormat { kaggle, extended, custom }

class ImportResult {
  ImportResult(this.resumes, this.format, this.rowCount);
  final List<Resume> resumes;
  final CsvFormat format;
  final int rowCount;
}

/// Parses talent CSVs into [Resume]s. Detects the Kaggle (9-column) and Extended
/// (35-column) datasets, with a best-effort custom fallback — matching the
/// original Android importer's behaviour.
class CsvImporter {
  static ImportResult import(String content, {String sourceFile = 'import.csv'}) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    if (rows.isEmpty) {
      return ImportResult([], CsvFormat.custom, 0);
    }

    final headers = rows.first
        .map((h) => _cleanHeader(h.toString()))
        .toList();
    final format = _detectFormat(headers);

    final resumes = <Resume>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final values = <String, String>{};
      for (var c = 0; c < headers.length && c < row.length; c++) {
        values[headers[c]] = row[c].toString().trim();
      }
      resumes.add(_map(values, format, sourceFile, i));
    }
    return ImportResult(resumes, format, resumes.length);
  }

  static String _cleanHeader(String h) => h
      .replaceAll('﻿', '')
      .runes
      .where((r) => r >= 32 && r <= 126)
      .map((r) => String.fromCharCode(r))
      .join()
      .trim()
      .toLowerCase();

  static CsvFormat _detectFormat(List<String> headers) {
    final set = headers.toSet();
    if (set.contains('career_objective') ||
        set.contains('professional_company_names') ||
        set.contains('educational_institution_name')) {
      return CsvFormat.extended;
    }
    if (set.contains('skills') &&
        (set.contains('name') || set.contains('category'))) {
      return CsvFormat.kaggle;
    }
    return CsvFormat.custom;
  }

  static Resume _map(
    Map<String, String> v,
    CsvFormat format,
    String sourceFile,
    int rowIndex,
  ) {
    switch (format) {
      case CsvFormat.kaggle:
        return _mapKaggle(v, sourceFile, rowIndex);
      case CsvFormat.extended:
        return _mapExtended(v, sourceFile, rowIndex);
      case CsvFormat.custom:
        return _mapCustom(v, sourceFile, rowIndex);
    }
  }

  static Resume _mapKaggle(Map<String, String> v, String src, int i) {
    final rawText = v.values.where((s) => s.isNotEmpty).join(' ');
    return Resume(
      resumeId: _get(v, ['id']) ?? 'kaggle_$i',
      fullName: _get(v, ['name', 'full_name']) ?? 'Candidate $i',
      email: _get(v, ['email']) ?? '',
      phoneNumber: _get(v, ['phone', 'phone_number']) ?? '',
      summary: _get(v, ['summary', 'objective']) ?? '',
      skills: _get(v, ['skills']) ?? '',
      experience: _get(v, ['experience']) ?? '',
      education: _get(v, ['education']) ?? '',
      certifications: _get(v, ['certifications']) ?? '',
      category: _get(v, ['category']) ?? '',
      rawText: rawText,
      fileFormat: 'csv',
      sourceFile: src,
    );
  }

  static Resume _mapExtended(Map<String, String> v, String src, int i) {
    final skills = _combine([
      _get(v, ['skills']),
      _get(v, ['related_skils_in_job']),
      _get(v, ['certification_skills']),
      _get(v, ['skills_required']),
    ]);
    final education = _joinParts([
      _label('Degree', _get(v, ['degree_names'])),
      _label('Institution', _get(v, ['educational_institution_name'])),
      _label('Major', _get(v, ['major_field_of_studies'])),
      _label('Year', _get(v, ['passing_years'])),
      _label('Result', _get(v, ['educational_results'])),
    ]);
    final experience = _joinParts([
      _label('Position', _get(v, ['positions'])),
      _label('Company', _get(v, ['professional_company_names'])),
      _label('Location', _get(v, ['locations'])),
      _label('Responsibilities', _get(v, ['responsibilities'])),
    ]);
    final certifications = _joinParts([
      _label('Provider', _get(v, ['certification_providers'])),
      _label('Skills', _get(v, ['certification_skills'])),
      _label('Issued', _get(v, ['issue_dates'])),
    ]);
    final summary = _get(v, ['career_objective']) ?? '';
    final rawText = [summary, skills, education, experience, certifications]
        .where((s) => s.isNotEmpty)
        .join('\n\n');
    final category = _get(v, ['job_position_name']) ?? '';

    return Resume(
      resumeId: 'extended_$i',
      fullName: _get(v, ['name', 'full_name']) ?? 'Candidate $i',
      summary: summary,
      skills: skills,
      experience: experience,
      education: education,
      certifications: certifications,
      category: category,
      rawText: rawText,
      fileFormat: 'csv',
      sourceFile: src,
    );
  }

  static Resume _mapCustom(Map<String, String> v, String src, int i) {
    final rawText = v.values.where((s) => s.isNotEmpty).join(' ');
    return Resume(
      resumeId: 'custom_$i',
      fullName: _get(v, ['name', 'fullname', 'full_name']) ?? 'Candidate $i',
      email: _get(v, ['email']) ?? '',
      phoneNumber: _get(v, ['phone', 'phonenumber', 'phone_number']) ?? '',
      summary: _get(v, ['summary', 'objective']) ?? '',
      skills: _get(v, ['skills']) ?? '',
      experience: _get(v, ['experience']) ?? '',
      education: _get(v, ['education']) ?? '',
      category: _get(v, ['category', 'role', 'position']) ?? '',
      rawText: rawText,
      fileFormat: 'csv',
      sourceFile: src,
    );
  }

  static String? _get(Map<String, String> v, List<String> keys) {
    for (final k in keys) {
      final value = v[k];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String _combine(List<String?> sets) {
    final seen = <String>{};
    for (final set in sets) {
      if (set == null) continue;
      for (final s in set.split(RegExp(r'[,;|]'))) {
        final t = s.trim();
        if (t.isNotEmpty) seen.add(t);
      }
    }
    return seen.join(', ');
  }

  static String? _label(String label, String? value) =>
      (value == null || value.isEmpty) ? null : '$label: $value';

  static String _joinParts(List<String?> parts) =>
      parts.whereType<String>().join(' | ');
}
