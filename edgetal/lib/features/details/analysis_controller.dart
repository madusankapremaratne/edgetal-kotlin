import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/resume.dart';
import '../../domain/llm/candidate_agent.dart';

sealed class AnalysisState {
  const AnalysisState();
}

class AnalysisIdle extends AnalysisState {
  const AnalysisIdle();
}

class AnalysisRunning extends AnalysisState {
  const AnalysisRunning(this.step);
  final String step;
}

class AnalysisDone extends AnalysisState {
  const AnalysisDone(this.reasoning, this.verdict, this.onDevice);
  final String reasoning;
  final String verdict;

  /// True if produced by the real on-device model; false if the offline
  /// heuristic was used (the UI badges this clearly).
  final bool onDevice;
}

class AnalysisFailed extends AnalysisState {
  const AnalysisFailed(this.message);
  final String message;
}

class AnalysisController extends StateNotifier<AnalysisState> {
  AnalysisController(this._ref) : super(const AnalysisIdle());

  final Ref _ref;

  Future<void> analyze(Resume resume, String role) async {
    if (role.trim().isEmpty) return;
    final agent = _ref.read(candidateAgentProvider);
    final llm = _ref.read(llmProviderProvider);
    await llm.initialize();

    await for (final step in agent.evaluateCandidate(resume, role)) {
      switch (step) {
        case AgentThinking(:final message) || AgentProcessing(:final message):
          state = AnalysisRunning(message);
        case AgentFinalResult(:final content, :final reasoning):
          state = AnalysisDone(reasoning, content, llm.isNativeActive);
        case AgentError(:final message):
          state = AnalysisFailed(message);
      }
    }
  }

  void reset() => state = const AnalysisIdle();
}

final analysisControllerProvider =
    StateNotifierProvider.autoDispose<AnalysisController, AnalysisState>(
  (ref) => AnalysisController(ref),
);
