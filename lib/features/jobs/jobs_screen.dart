import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/job.dart';
import '../shared/page_scaffold.dart';
import 'jobs_controller.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsState = ref.watch(jobsControllerProvider);
    final jobs = jobsState.jobs;

    return PageScaffold(
      title: 'Jobs',
      subtitle: "Roles you're hiring for — tracked on this device",
      actions: [
        AppGradientButton(
          onPressed: () => _showAddJobDialog(context, ref),
          icon: Icons.add,
          label: '+ New job',
        ),
      ],
      scrollableBody: true,
      body: Column(
        children: [
          for (final job in jobs) ...[
            _JobCard(job: job),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  void _showAddJobDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final descriptionController = TextEditingController();
    final skillsController = TextEditingController();
    final locationController = TextEditingController(text: 'Remote');
    String employmentType = 'Full-Time';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Job Role'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title *',
                    hintText: 'e.g. Senior Flutter Engineer',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company / Team',
                    hintText: 'e.g. Mobile Engineering Team',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g. Remote or San Francisco, CA',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: employmentType,
                  decoration: const InputDecoration(labelText: 'Employment Type'),
                  items: const [
                    DropdownMenuItem(value: 'Full-Time', child: Text('Full-Time')),
                    DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                    DropdownMenuItem(value: 'Part-Time', child: Text('Part-Time')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => employmentType = val);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Required Competencies (comma separated)',
                    hintText: 'e.g. Flutter, Dart, iOS, MediaPipe',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Job Description & Requirements *',
                    hintText: 'Paste complete role responsibilities and requirements...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.midnightNavy,
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isNotEmpty && description.isNotEmpty) {
                  final skills = skillsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  await ref.read(jobsControllerProvider.notifier).addJob(
                        title: title,
                        company: companyController.text.trim().isEmpty
                            ? 'Internal Team'
                            : companyController.text.trim(),
                        description: description,
                        requiredSkills: skills,
                        location: locationController.text.trim().isEmpty
                            ? 'Remote'
                            : locationController.text.trim(),
                        employmentType: employmentType,
                      );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create Job'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final JobRole job;

  @override
  Widget build(BuildContext context) {
    final isOpen = job.status == 'Open';

    return GestureDetector(
      onTap: () => context.push('/job/${job.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isOpen ? context.colors.brandSubtle : context.colors.surfaceSubtle,
          borderRadius: AppRadius.cardXl,
          border: Border.all(
            color: context.colors.border,
            width: 1,
          ),
          boxShadow: AppShadow.soft(
            isOpen ? AppPalette.oceanTeal : AppPalette.midnightNavy,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? AppPalette.oceanTeal : AppPalette.midnightNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${job.company} · ${job.location} (${job.employmentType})',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final skill in job.requiredSkills.take(4))
                    AppPill(
                      label: skill,
                      color: context.colors.brand,
                      background: context.colors.brandSubtle,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StageDot(
                  color: AppPalette.oceanTeal,
                  label: '${job.shortlisted} shortlisted',
                ),
                const SizedBox(width: 12),
                _StageDot(
                  color: AppPalette.warmGold,
                  label: '${job.interviewing} interviewing',
                ),
                const SizedBox(width: 12),
                _StageDot(
                  color: AppPalette.vibrantAmber,
                  label: '${job.offer} offer',
                ),
                const SizedBox(width: 12),
                _StageDot(
                  color: AppPalette.privacyEmerald,
                  label: '${job.placed} placed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
