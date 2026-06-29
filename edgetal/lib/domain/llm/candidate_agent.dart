import '../../data/models/resume.dart';
import '../monitor/performance_monitor.dart';
import 'llm_provider.dart';

/// Steps the analysis UI can observe while the agent reasons.
sealed class AgentStep {
  const AgentStep();
}

class AgentThinking extends AgentStep {
  const AgentThinking(this.message);
  final String message;
}

class AgentProcessing extends AgentStep {
  const AgentProcessing(this.message);
  final String message;
}

class AgentFinalResult extends AgentStep {
  const AgentFinalResult(this.content, this.reasoning);
  final String content;
  final String reasoning;
}

class AgentError extends AgentStep {
  const AgentError(this.message);
  final String message;
}

/// Reasoning agent (the "Act" phase). Runs a single structured chain-of-thought
/// pass over a candidate against a pasted role, then splits the response into
/// reasoning and a final verdict. Emits progress as a stream.
class CandidateAgent {
  CandidateAgent(this._llm, this._monitor);

  final LlmProvider _llm;
  final PerformanceMonitor _monitor;

  Stream<AgentStep> evaluateCandidate(
    Resume resume,
    String roleDescription,
  ) async* {
    final stopwatch = Stopwatch()..start();
    try {
      yield const AgentThinking(
          'Extracting key requirements from the role…');
      final prompt = _buildPrompt(resume, roleDescription);

      yield const AgentProcessing(
          'Analysing candidate evidence against requirements…');
      final response = await _llm.generateResponse(prompt);

      final (reasoning, result) = _parse(response);
      stopwatch.stop();
      _monitor.recordLatency(
        type: 'agentic_reasoning',
        name: 'Candidate Evaluation',
        durationMs: stopwatch.elapsedMilliseconds,
      );
      yield AgentFinalResult(result, reasoning);
    } catch (e) {
      yield AgentError(e.toString());
    }
  }

  String _buildPrompt(Resume resume, String roleDescription) {
    return '''
You are an expert HR Recruitment Agent. Perform a deep analysis of the candidate fit for the following role.

ROLE DESCRIPTION:
$roleDescription

CANDIDATE DATA:
Summary: ${resume.summary}
Skills: ${resume.skills}
Experience: ${resume.experience}

INSTRUCTIONS:
Perform your analysis in three steps:
1. [THOUGHT]: Identify the core 3 requirements for this role.
2. [EVIDENCE]: Find specific evidence in the candidate's data that matches or contradicts these requirements.
3. [CONCLUSION]: Provide a final recommendation (Yes/No/Maybe) with a brief summary.

Format your response exactly as follows:
THOUGHT: (your analysis here)
EVIDENCE: (your extracted evidence here)
CONCLUSION: (your final answer here)
''';
  }

  (String reasoning, String result) _parse(String response) {
    final thought = _between(response, 'THOUGHT:', 'EVIDENCE:').trim();
    final evidence = _between(response, 'EVIDENCE:', 'CONCLUSION:').trim();
    final conclusion = _after(response, 'CONCLUSION:').trim();

    final reasoning = (thought.isNotEmpty || evidence.isNotEmpty)
        ? '**Analysis**\n$thought\n\n**Evidence found**\n$evidence'
        : 'No detailed reasoning provided.';
    final result = conclusion.isNotEmpty ? conclusion : response.trim();
    return (reasoning, result);
  }

  String _between(String text, String start, String end) {
    final i = text.indexOf(start);
    if (i < 0) return '';
    final from = i + start.length;
    final j = text.indexOf(end, from);
    return j < 0 ? text.substring(from) : text.substring(from, j);
  }

  String _after(String text, String start) {
    final i = text.indexOf(start);
    return i < 0 ? '' : text.substring(i + start.length);
  }
}
