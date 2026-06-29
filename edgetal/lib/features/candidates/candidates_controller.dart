import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/resume.dart';
import '../../data/repository/resume_repository.dart';

class CandidatesState {
  const CandidatesState({
    this.loading = true,
    this.resumes = const [],
    this.embeddingCount = 0,
    this.filter = '',
    this.error,
  });

  final bool loading;
  final List<Resume> resumes;
  final int embeddingCount;
  final String filter;
  final String? error;

  int get total => resumes.length;
  int get embeddedCount => resumes.where((r) => r.isEmbedded).length;

  List<Resume> get visible {
    if (filter.trim().isEmpty) return resumes;
    final q = filter.toLowerCase();
    return resumes
        .where((r) =>
            r.fullName.toLowerCase().contains(q) ||
            r.skills.toLowerCase().contains(q) ||
            r.category.toLowerCase().contains(q))
        .toList();
  }

  CandidatesState copyWith({
    bool? loading,
    List<Resume>? resumes,
    int? embeddingCount,
    String? filter,
    String? error,
  }) {
    return CandidatesState(
      loading: loading ?? this.loading,
      resumes: resumes ?? this.resumes,
      embeddingCount: embeddingCount ?? this.embeddingCount,
      filter: filter ?? this.filter,
      error: error,
    );
  }
}

class CandidatesController extends StateNotifier<CandidatesState> {
  CandidatesController(this._repo, this._ref) : super(const CandidatesState()) {
    load();
  }

  final ResumeRepository _repo;
  final Ref _ref;

  Future<void> load() async {
    try {
      final resumes = await _repo.getAllResumes();
      final embeddingCount = await _repo.getEmbeddingCount();
      state = state.copyWith(
        loading: false,
        resumes: resumes,
        embeddingCount: embeddingCount,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter(String value) => state = state.copyWith(filter: value);

  Future<void> delete(int id) async {
    await _repo.deleteResume(id);
    _ref.read(libraryRevisionProvider.notifier).state++;
    await load();
  }
}

final candidatesControllerProvider =
    StateNotifierProvider<CandidatesController, CandidatesState>((ref) {
  // Rebuild when the library changes elsewhere (import, delete).
  ref.watch(libraryRevisionProvider);
  return CandidatesController(ref.watch(resumeRepositoryProvider), ref);
});
