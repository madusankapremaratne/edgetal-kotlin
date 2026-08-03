import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/resume.dart';
import '../../data/models/search_query.dart';
import '../../data/repository/resume_repository.dart';
import '../../domain/embedding/embedding_provider.dart';
import '../../domain/llm/search_agent.dart';
import '../../domain/search/vector_search_engine.dart';

class SearchResultUi {
  SearchResultUi(this.result, this.resume);
  final SearchResult result;
  final Resume? resume;
}

sealed class SearchUiState {
  const SearchUiState();
}

class SearchIdle extends SearchUiState {
  const SearchIdle();
}

class SearchLoading extends SearchUiState {
  const SearchLoading();
}

class SearchAgenticLoading extends SearchUiState {
  const SearchAgenticLoading(this.step);
  final String step;
}

class SearchSuccess extends SearchUiState {
  const SearchSuccess(this.results, {this.reformulatedQuery});
  final List<SearchResultUi> results;
  final String? reformulatedQuery;
}

class SearchError extends SearchUiState {
  const SearchError(this.message);
  final String message;
}

class SearchModel {
  const SearchModel({
    this.state = const SearchIdle(),
    this.query = '',
    this.executionMs = 0,
    this.resultCount = 0,
    this.searchCount = 0,
  });

  final SearchUiState state;
  final String query;
  final int executionMs;
  final int resultCount;
  final int searchCount;

  SearchModel copyWith({
    SearchUiState? state,
    String? query,
    int? executionMs,
    int? resultCount,
    int? searchCount,
  }) =>
      SearchModel(
        state: state ?? this.state,
        query: query ?? this.query,
        executionMs: executionMs ?? this.executionMs,
        resultCount: resultCount ?? this.resultCount,
        searchCount: searchCount ?? this.searchCount,
      );
}

class SearchController extends StateNotifier<SearchModel> {
  SearchController(
    this._repo,
    this._embedder,
    this._engine,
    this._agent,
  ) : super(const SearchModel()) {
    _embedder.initialize();
  }

  final ResumeRepository _repo;
  final EmbeddingProvider _embedder;
  final VectorSearchEngine _engine;
  final SearchAgent _agent;

  Future<void> search(String query, {int topK = 10}) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(state: const SearchIdle());
      return;
    }
    state = state.copyWith(state: const SearchLoading());
    try {
      final results = await _runSearch(query, topK);
      state = state.copyWith(state: SearchSuccess(await _wrap(results)));
    } catch (e) {
      state = state.copyWith(state: SearchError(_message(e)));
    }
  }

  Future<void> agenticSearch(String query, {String? feedback, int topK = 10}) async {
    if (query.trim().isEmpty) return;
    try {
      state = state.copyWith(state: const SearchAgenticLoading('Performing initial search…'));
      final initial = await _runSearch(query, topK);
      final topScore = initial.isEmpty ? 0.0 : initial.first.similarityScore;
      final needsReformulation =
          initial.isEmpty || topScore < 0.6 || (feedback?.isNotEmpty ?? false);

      if (!needsReformulation) {
        state = state.copyWith(state: SearchSuccess(await _wrap(initial)));
        return;
      }

      state = state.copyWith(
          state: const SearchAgenticLoading('Reformulating query from results…'));
      final reformulated =
          await _agent.reformulateQuery(query, initial, userFeedback: feedback);

      state = state.copyWith(
          state: SearchAgenticLoading('Searching with: "$reformulated"'));
      final finalResults = await _runSearch(reformulated, topK);
      state = state.copyWith(
        state: SearchSuccess(await _wrap(finalResults),
            reformulatedQuery: reformulated),
      );
    } catch (e) {
      state = state.copyWith(state: SearchError(_message(e)));
    }
  }

  Future<void> recordFeedback(bool satisfied) async {
    final history = await _repo.getSearchHistory(limit: 1);
    if (history.isEmpty) return;
    final last = history.first
      ..wasUserSatisfied = satisfied;
    await _repo.recordSearchQuery(last);
    if (!satisfied) {
      await agenticSearch(state.query);
    }
  }

  void clear() => state = const SearchModel();

  Future<List<SearchResult>> _runSearch(String query, int topK) async {
    final sw = Stopwatch()..start();
    final queryEmbedding = await _embedder.embedText(query);
    final candidates = await _repo.getAllEmbeddings();
    if (candidates.isEmpty) {
      throw StateError('No candidates indexed yet. Import resumes first.');
    }
    final results = await _engine.search(queryEmbedding, candidates, topK: topK);
    sw.stop();

    state = state.copyWith(
      query: query,
      executionMs: sw.elapsedMilliseconds,
      resultCount: results.length,
      searchCount: state.searchCount + 1,
    );
    await _repo.recordSearchQuery(SearchQuery(
      queryText: query,
      executionTimeMs: sw.elapsedMilliseconds,
      resultCount: results.length,
      topScoreValue: results.isEmpty ? 0 : results.first.similarityScore,
    ));
    return results;
  }

  Future<List<SearchResultUi>> _wrap(List<SearchResult> results) async {
    final out = <SearchResultUi>[];
    for (final r in results) {
      out.add(SearchResultUi(r, await _repo.getResume(r.resumeId)));
    }
    return out;
  }

  String _message(Object e) =>
      e is StateError ? e.message : e.toString().replaceFirst('Exception: ', '');
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchModel>((ref) {
  ref.watch(libraryRevisionProvider);
  return SearchController(
    ref.watch(resumeRepositoryProvider),
    ref.watch(embeddingProviderProvider),
    ref.watch(vectorSearchEngineProvider),
    ref.watch(searchAgentProvider),
  );
});
