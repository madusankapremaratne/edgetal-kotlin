import '../search/vector_search_engine.dart';
import 'llm_provider.dart';

/// Query-understanding agent (the "Plan" phase). Uses the local LLM to rewrite a
/// talent-search query when the initial results look weak or the user pushes
/// back. Always degrades gracefully to the original query.
class SearchAgent {
  SearchAgent(this._llm);

  final LlmProvider _llm;

  Future<String> reformulateQuery(
    String originalQuery,
    List<SearchResult> results, {
    String? userFeedback,
  }) async {
    try {
      final prompt = _buildPrompt(originalQuery, results, userFeedback);
      final response = await _llm.generateResponse(prompt);
      return _parse(response, originalQuery);
    } catch (_) {
      return originalQuery;
    }
  }

  String _buildPrompt(
    String originalQuery,
    List<SearchResult> results,
    String? userFeedback,
  ) {
    final resultContext = results.isNotEmpty
        ? results
            .take(2)
            .map((r) => '- ${_take(r.segmentText, 70)}...')
            .join('\n')
        : 'No relevant results found.';
    final feedbackSection =
        (userFeedback != null && userFeedback.trim().isNotEmpty)
            ? '\nUSER FEEDBACK: $userFeedback'
            : '';

    return '''
You are a Search Optimization Agent. Your goal is to improve a talent search query.

ORIGINAL QUERY: $originalQuery
$feedbackSection

CURRENT RESULTS PREVIEW:
$resultContext

TASK:
Analyze the mismatch and generate a single, optimized search query.
The optimized query must be a natural language description of the ideal candidate.

CRITICAL CONSTRAINTS:
- DO NOT use keyword-stuffing.
- DO NOT include your analysis in the NEW_QUERY section.
- ONLY provide a semantic, descriptive query.

Format:
ANALYSIS: (1 sentence why the change is needed)
NEW_QUERY: (the optimized query string only)
''';
  }

  String _parse(String response, String originalQuery) {
    final afterTag = response.contains('NEW_QUERY:')
        ? response.split('NEW_QUERY:').last
        : '';
    final line = afterTag
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final cleaned = _take(_unwrap(line), 150);
    if (cleaned.isNotEmpty && cleaned != originalQuery) return cleaned;
    return originalQuery;
  }

  String _unwrap(String s) {
    var r = s;
    if (r.startsWith('"') && r.endsWith('"') && r.length > 1) {
      r = r.substring(1, r.length - 1);
    }
    if (r.startsWith("'") && r.endsWith("'") && r.length > 1) {
      r = r.substring(1, r.length - 1);
    }
    return r;
  }

  String _take(String s, int n) => s.length <= n ? s : s.substring(0, n);
}
