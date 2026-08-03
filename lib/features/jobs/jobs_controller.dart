import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/job.dart';
import '../../data/models/job_candidate_link.dart';
import '../../domain/embedding/embedding_provider.dart';

class JobsState {
  const JobsState({
    this.jobs = const [],
    this.links = const [],
  });

  final List<JobRole> jobs;
  final List<JobCandidateLink> links;

  JobsState copyWith({
    List<JobRole>? jobs,
    List<JobCandidateLink>? links,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      links: links ?? this.links,
    );
  }
}

class JobsController extends StateNotifier<JobsState> {
  JobsController(this._embedder)
      : super(JobsState(
          jobs: _initialJobs,
          links: _initialLinks,
        ));

  final EmbeddingProvider _embedder;

  static final List<JobRole> _initialJobs = [
    JobRole(
      id: '1',
      title: 'Senior Backend Engineer',
      company: 'Northwind Systems',
      description:
          'Seeking a Senior Backend Engineer with strong expertise in Kotlin, Microservices, PostgreSQL, Docker, and high-scale REST APIs.',
      requiredSkills: ['Kotlin', 'Microservices', 'PostgreSQL', 'Docker', 'REST API'],
      location: 'Remote',
      employmentType: 'Full-Time',
      status: 'Open',
      shortlisted: 1,
      interviewing: 1,
      offer: 0,
      placed: 0,
    ),
    JobRole(
      id: '2',
      title: 'Senior Mobile Engineer (Flutter/iOS)',
      company: 'Halo Studio',
      description:
          'Looking for a Senior Flutter & iOS engineer with experience in State Management, CoreML, Vector Embeddings, and Clean Architecture.',
      requiredSkills: ['Flutter', 'iOS', 'Dart', 'Swift', 'Clean Architecture'],
      location: 'San Francisco, CA',
      employmentType: 'Full-Time',
      status: 'Open',
      shortlisted: 1,
      interviewing: 0,
      offer: 0,
      placed: 0,
    ),
    JobRole(
      id: '3',
      title: 'AI / ML Engineer',
      company: 'Vantage Analytics',
      description:
          'Lead AI Engineer responsible for on-device LLM fine-tuning, MediaPipe text embedders, and vector search engines.',
      requiredSkills: ['Python', 'MediaPipe', 'LLM', 'TensorFlow', 'Vector DB'],
      location: 'Hybrid',
      employmentType: 'Full-Time',
      status: 'Filled',
      shortlisted: 0,
      interviewing: 0,
      offer: 0,
      placed: 1,
    ),
  ];

  static final List<JobCandidateLink> _initialLinks = [
    JobCandidateLink(
      id: 'l1',
      jobId: '1',
      candidateId: '1',
      stage: 'Shortlisted',
      fitScore: 0.89,
    ),
    JobCandidateLink(
      id: 'l2',
      jobId: '1',
      candidateId: '2',
      stage: 'Interviewing',
      fitScore: 0.94,
    ),
    JobCandidateLink(
      id: 'l3',
      jobId: '2',
      candidateId: '3',
      stage: 'Shortlisted',
      fitScore: 0.87,
    ),
    JobCandidateLink(
      id: 'l4',
      jobId: '3',
      candidateId: '4',
      stage: 'Placed',
      fitScore: 0.96,
    ),
  ];

  Future<void> addJob({
    required String title,
    required String company,
    required String description,
    required List<String> requiredSkills,
    required String location,
    required String employmentType,
  }) async {
    List<double>? vec;
    try {
      vec = await _embedder.embedText('$title $description ${requiredSkills.join(" ")}');
    } catch (_) {}

    final newJob = JobRole(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      company: company,
      description: description,
      requiredSkills: requiredSkills,
      location: location,
      employmentType: employmentType,
      status: 'Open',
      embedding: vec,
    );

    state = state.copyWith(jobs: [...state.jobs, newJob]);
  }

  void assignCandidateToJob({
    required String jobId,
    required String candidateId,
    required String stage,
    double fitScore = 0.0,
    String aiThought = '',
    String aiEvidence = '',
    String aiConclusion = '',
  }) {
    final existingIndex = state.links.indexWhere(
      (l) => l.jobId == jobId && l.candidateId == candidateId,
    );

    List<JobCandidateLink> updatedLinks;
    if (existingIndex >= 0) {
      updatedLinks = List.from(state.links);
      updatedLinks[existingIndex] = updatedLinks[existingIndex].copyWith(
        stage: stage,
        fitScore: fitScore > 0 ? fitScore : updatedLinks[existingIndex].fitScore,
        aiThought: aiThought.isNotEmpty ? aiThought : updatedLinks[existingIndex].aiThought,
        aiEvidence: aiEvidence.isNotEmpty ? aiEvidence : updatedLinks[existingIndex].aiEvidence,
        aiConclusion: aiConclusion.isNotEmpty ? aiConclusion : updatedLinks[existingIndex].aiConclusion,
        updatedAt: DateTime.now(),
      );
    } else {
      final newLink = JobCandidateLink(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: jobId,
        candidateId: candidateId,
        stage: stage,
        fitScore: fitScore,
        aiThought: aiThought,
        aiEvidence: aiEvidence,
        aiConclusion: aiConclusion,
      );
      updatedLinks = [...state.links, newLink];
    }

    _recalculateStageCounts(updatedLinks);
  }

  void updateCandidateStage(String jobId, String candidateId, String newStage) {
    final updatedLinks = state.links.map((l) {
      if (l.jobId == jobId && l.candidateId == candidateId) {
        return l.copyWith(stage: newStage, updatedAt: DateTime.now());
      }
      return l;
    }).toList();

    _recalculateStageCounts(updatedLinks);
  }

  void removeCandidateFromJob(String jobId, String candidateId) {
    final updatedLinks = state.links
        .where((l) => !(l.jobId == jobId && l.candidateId == candidateId))
        .toList();
    _recalculateStageCounts(updatedLinks);
  }

  void _recalculateStageCounts(List<JobCandidateLink> newLinks) {
    final updatedJobs = state.jobs.map((job) {
      final jobLinks = newLinks.where((l) => l.jobId == job.id).toList();
      final shortlisted = jobLinks.where((l) => l.stage == 'Shortlisted').length;
      final interviewing = jobLinks.where((l) => l.stage == 'Interviewing').length;
      final offer = jobLinks.where((l) => l.stage == 'Offer').length;
      final placed = jobLinks.where((l) => l.stage == 'Placed').length;

      return job.copyWith(
        shortlisted: shortlisted,
        interviewing: interviewing,
        offer: offer,
        placed: placed,
      );
    }).toList();

    state = state.copyWith(jobs: updatedJobs, links: newLinks);
  }

  void deleteJob(String jobId) {
    final updatedJobs = state.jobs.where((j) => j.id != jobId).toList();
    final updatedLinks = state.links.where((l) => l.jobId != jobId).toList();
    state = state.copyWith(jobs: updatedJobs, links: updatedLinks);
  }
}

final jobsControllerProvider =
    StateNotifierProvider<JobsController, JobsState>((ref) {
  return JobsController(ref.watch(embeddingProviderProvider));
});
