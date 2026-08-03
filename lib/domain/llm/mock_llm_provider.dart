import 'llm_provider.dart';

/// Offline stand-in for the on-device LLM.
///
/// It recognises the two prompt shapes the app sends (candidate analysis and
/// query reformulation) and returns responses in exactly the format the agents
/// parse — so the agentic search and AI-analysis flows are fully demonstrable
/// without the ~1.3 GB Gemma model. Marked clearly as a heuristic in the UI.
class MockLlmProvider implements LlmProvider {
  String _activeBackend = 'CPU';

  @override
  bool get isModelAvailable => true;

  @override
  bool get isNativeActive => false;

  @override
  String get activeBackend => _activeBackend;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> setBackend(String backend) async {
    _activeBackend = backend;
  }

  @override
  Future<String> generateResponse(String prompt) async {
    // Simulate a little inference latency so progress states are visible.
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (prompt.contains('Search Optimization Agent')) {
      return _reformulation(prompt);
    }
    if (prompt.contains('HR Recruitment Agent')) {
      return _candidateAnalysis(prompt);
    }
    return 'OK';
  }

  String _reformulation(String prompt) {
    final original = _between(prompt, 'ORIGINAL QUERY:', '\n').trim();
    final enriched = _enrich(original);
    return 'ANALYSIS: The original query was broad; tightening it around concrete '
        'skills and seniority improves candidate fit.\n'
        'NEW_QUERY: $enriched';
  }

  String _candidateAnalysis(String prompt) {
    final role = _between(prompt, 'ROLE DESCRIPTION:', 'CANDIDATE DATA:').trim();
    final skills = _between(prompt, 'Skills:', 'Experience:').trim();
    final topSkills = skills
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
    final skillLine =
        topSkills.isEmpty ? 'the listed competencies' : topSkills.join(', ');
    final verdict = topSkills.length >= 2 ? 'Yes' : 'Maybe';

    return 'THOUGHT: The role "${_short(role)}" calls for relevant domain '
        'expertise, demonstrated delivery, and collaboration.\n'
        'EVIDENCE: The candidate lists $skillLine, with supporting experience '
        'that maps to the core requirements.\n'
        'CONCLUSION: $verdict — a credible fit worth shortlisting; confirm depth '
        'of $skillLine in a screening call.';
  }

  String _enrich(String q) {
    if (q.isEmpty) return 'experienced professional with relevant domain skills';
    return '$q with proven hands-on delivery and strong collaboration skills';
  }

  String _short(String s) => s.length <= 60 ? s : '${s.substring(0, 60)}…';

  String _between(String text, String start, String end) {
    final i = text.indexOf(start);
    if (i < 0) return '';
    final from = i + start.length;
    final j = text.indexOf(end, from);
    return j < 0 ? text.substring(from) : text.substring(from, j);
  }
}
