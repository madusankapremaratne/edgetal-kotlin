import 'dart:convert';

import 'llm_provider.dart';

/// Structured fields the on-device LLM extracts from a raw resume text blob.
/// Every field defaults to empty — mirrors [Resume]'s own field defaults so
/// callers can map this straight across without extra null-handling.
class ExtractedFields {
  const ExtractedFields({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.skills = '',
    this.experience = '',
    this.education = '',
    this.certifications = '',
    this.summary = '',
    this.category = '',
  });

  final String fullName;
  final String email;
  final String phone;
  final String skills;
  final String experience;
  final String education;
  final String certifications;
  final String summary;
  final String category;

  factory ExtractedFields.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] as String?)?.trim() ?? '';
    return ExtractedFields(
      fullName: s('full_name'),
      email: s('email'),
      phone: s('phone'),
      skills: s('skills'),
      experience: s('experience'),
      education: s('education'),
      certifications: s('certifications'),
      summary: s('summary'),
      category: s('category'),
    );
  }
}

/// Turns raw resume text into [ExtractedFields] using the app's existing
/// on-device LLM. Mirrors [CandidateAgent]'s "prompt the local model, parse
/// defensively, never throw for a bad response" shape — here the parse target
/// is JSON instead of labelled text sections, since there's no free-form
/// reasoning to preserve, just structured fields.
class ResumeExtractionAgent {
  ResumeExtractionAgent(this._llm);

  final LlmProvider _llm;

  static const _maxRawTextChars = 6000;

  /// Returns `null` (never throws) if the model's response can't be parsed
  /// into valid JSON even after one repair attempt, so batch callers can
  /// record a skip and move on to the next file.
  Future<ExtractedFields?> extractFields(String rawText) async {
    final truncated = rawText.length > _maxRawTextChars
        ? rawText.substring(0, _maxRawTextChars)
        : rawText;

    final response = await _llm.generateResponse(_buildPrompt(truncated));
    final parsed = _tryParse(response);
    if (parsed != null) return parsed;

    // One repair retry — small on-device models sometimes wrap the JSON in
    // prose or markdown fences despite instructions not to.
    final repaired = await _llm.generateResponse(
      '${_buildPrompt(truncated)}\n\n'
      'Your previous response was not valid JSON. Return ONLY the JSON '
      'object, nothing else.',
    );
    return _tryParse(repaired);
  }

  String _buildPrompt(String rawText) => '''
You are an expert HR data-extraction assistant. Extract structured fields
from the raw resume text below. Respond with ONLY a single JSON object, no
prose, no markdown code fences, matching exactly this shape:

{
  "full_name": "string or empty",
  "email": "string or empty",
  "phone": "string or empty",
  "skills": "comma-separated string or empty",
  "experience": "string summary or empty",
  "education": "string summary or empty",
  "certifications": "string or empty",
  "summary": "1-3 sentence professional summary or empty",
  "category": "best-guess job category/title or empty"
}

RAW RESUME TEXT:
<<<
$rawText
>>>
''';

  ExtractedFields? _tryParse(String response) {
    var text = response.trim();
    // Strip markdown code fences if the model added them anyway.
    text = text.replaceAll(RegExp(r'^```(json)?', multiLine: true), '');
    text = text.replaceAll('```', '').trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end < 0 || end < start) return null;

    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is! Map<String, dynamic>) return null;
      return ExtractedFields.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
