import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/resume.dart';
import '../../data/repository/resume_repository.dart';

class DetailsState {
  const DetailsState({this.resume, this.highlight, this.loading = true, this.error});
  final Resume? resume;
  final String? highlight;
  final bool loading;
  final String? error;
}

class DetailsController extends StateNotifier<DetailsState> {
  DetailsController(this._repo, this.resumeId, this.highlight)
      : super(const DetailsState()) {
    load();
  }

  final ResumeRepository _repo;
  final int resumeId;
  final String? highlight;

  Future<void> load() async {
    try {
      final resume = await _repo.getResume(resumeId);
      if (resume == null) {
        state = const DetailsState(loading: false, error: 'Candidate not found');
        return;
      }
      state = DetailsState(resume: resume, highlight: highlight, loading: false);
    } catch (e) {
      state = DetailsState(loading: false, error: e.toString());
    }
  }
}

final detailsControllerProvider = StateNotifierProvider.family<DetailsController,
    DetailsState, ({int id, String? highlight})>((ref, args) {
  return DetailsController(
    ref.watch(resumeRepositoryProvider),
    args.id,
    args.highlight,
  );
});
