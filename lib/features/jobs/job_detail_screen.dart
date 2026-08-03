import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/job.dart';
import '../../data/models/job_candidate_link.dart';
import '../../data/models/resume.dart';
import '../candidates/candidates_controller.dart';
import '../shared/page_scaffold.dart';
import 'jobs_controller.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsControllerProvider);
    final job = jobsState.jobs.firstWhere(
      (j) => j.id == widget.jobId,
      orElse: () => JobRole(
        id: widget.jobId,
        title: 'Job Role Not Found',
        company: '',
        description: '',
      ),
    );

    final candidatesState = ref.watch(candidatesControllerProvider);
    final jobLinks = jobsState.links.where((l) => l.jobId == widget.jobId).toList();

    return PageScaffold(
      title: job.title,
      subtitle: '${job.company} · ${job.location} (${job.employmentType})',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      scrollableBody: false,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: 'Overview'),
              Tab(text: 'AI Matches (${candidatesState.resumes.length})'),
              Tab(text: 'Pipeline (${jobLinks.length})'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _JobOverviewTab(job: job),
                _JobAiMatchesTab(
                  job: job,
                  resumes: candidatesState.resumes,
                  links: jobLinks,
                ),
                _JobPipelineTab(
                  job: job,
                  resumes: candidatesState.resumes,
                  links: jobLinks,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobOverviewTab extends StatelessWidget {
  const _JobOverviewTab({required this.job});
  final JobRole job;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Job Overview', style: context.text.titleMedium),
                    AppPill(
                      label: job.status,
                      color: job.status == 'Open'
                          ? AppPalette.oceanTeal
                          : AppPalette.midnightNavy,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailChip(icon: Icons.location_on_outlined, label: job.location),
                    _DetailChip(icon: Icons.work_outline, label: job.employmentType),
                    _DetailChip(icon: Icons.business, label: job.company),
                  ],
                ),
                if (job.requiredSkills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Required Competencies', style: context.text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in job.requiredSkills)
                        AppPill(
                          label: skill,
                          color: context.colors.brand,
                          background: context.colors.brandSubtle,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Job Description', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  job.description.isEmpty
                      ? 'No detailed description provided.'
                      : job.description,
                  style: context.text.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _JobAiMatchesTab extends ConsumerWidget {
  const _JobAiMatchesTab({
    required this.job,
    required this.resumes,
    required this.links,
  });

  final JobRole job;
  final List<Resume> resumes;
  final List<JobCandidateLink> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resumes.isEmpty) {
      return Center(
        child: Text('No candidates in database yet. Import resumes to view matches.',
            style: context.text.bodyMedium),
      );
    }

    return ListView.builder(
      itemCount: resumes.length,
      itemBuilder: (context, index) {
        final resume = resumes[index];
        final existingLink = links.cast<JobCandidateLink?>().firstWhere(
              (l) => l?.candidateId == resume.id.toString(),
              orElse: () => null,
            );

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.colors.brandSubtle,
                    child: Text(
                      resume.fullName.isEmpty ? '?' : resume.fullName[0],
                      style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resume.fullName, style: context.text.titleSmall),
                        Text(resume.email, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  if (existingLink != null)
                    AppPill(
                      label: existingLink.stage,
                      color: AppPalette.privacyEmerald,
                      background: AppPalette.privacyEmerald.withValues(alpha: 0.12),
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      tooltip: 'Assign to stage',
                      onSelected: (stage) {
                        ref.read(jobsControllerProvider.notifier).assignCandidateToJob(
                              jobId: job.id,
                              candidateId: resume.id.toString(),
                              stage: stage,
                            );
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Shortlisted', child: Text('Shortlisted')),
                        const PopupMenuItem(value: 'Interviewing', child: Text('Interviewing')),
                        const PopupMenuItem(value: 'Offer', child: Text('Offer')),
                        const PopupMenuItem(value: 'Placed', child: Text('Placed')),
                      ],
                    ),
                ],
              ),
              if (resume.skillList.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final skill in resume.skillList.take(4))
                      AppPill(label: skill, color: context.colors.textSecondary),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _JobPipelineTab extends ConsumerWidget {
  const _JobPipelineTab({
    required this.job,
    required this.resumes,
    required this.links,
  });

  final JobRole job;
  final List<Resume> resumes;
  final List<JobCandidateLink> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (links.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: context.colors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No candidates assigned to this job pipeline yet.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Go to the AI Matches tab to add candidates.',
              style: context.text.bodySmall?.copyWith(color: context.colors.textMuted),
            ),
          ],
        ),
      );
    }

    final stages = ['Shortlisted', 'Interviewing', 'Offer', 'Placed'];

    return ListView(
      children: [
        for (final stage in stages) ...[
          _StageSection(
            stage: stage,
            job: job,
            links: links.where((l) => l.stage == stage).toList(),
            resumes: resumes,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StageSection extends ConsumerWidget {
  const _StageSection({
    required this.stage,
    required this.job,
    required this.links,
    required this.resumes,
  });

  final String stage;
  final JobRole job;
  final List<JobCandidateLink> links;
  final List<Resume> resumes;

  Color _stageColor(String s) {
    switch (s) {
      case 'Shortlisted':
        return AppPalette.oceanTeal;
      case 'Interviewing':
        return AppPalette.warmGold;
      case 'Offer':
        return AppPalette.vibrantAmber;
      case 'Placed':
        return AppPalette.privacyEmerald;
      default:
        return AppPalette.midnightNavy;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _stageColor(stage),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$stage (${links.length})',
                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (links.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          for (final link in links) ...[
            Builder(builder: (context) {
              final resume = resumes.cast<Resume?>().firstWhere(
                    (r) => r?.id.toString() == link.candidateId,
                    orElse: () => null,
                  );
              if (resume == null) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(resume.fullName, style: context.text.labelLarge),
                          Text(resume.email, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (newStage) {
                        if (newStage == 'Remove') {
                          ref.read(jobsControllerProvider.notifier).removeCandidateFromJob(
                                job.id,
                                resume.id.toString(),
                              );
                        } else {
                          ref.read(jobsControllerProvider.notifier).updateCandidateStage(
                                job.id,
                                resume.id.toString(),
                                newStage,
                              );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Shortlisted', child: Text('Move to Shortlisted')),
                        const PopupMenuItem(value: 'Interviewing', child: Text('Move to Interviewing')),
                        const PopupMenuItem(value: 'Offer', child: Text('Move to Offer')),
                        const PopupMenuItem(value: 'Placed', child: Text('Move to Placed')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'Remove',
                          child: Text('Remove from Job', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
