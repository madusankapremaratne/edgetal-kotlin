import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../data/models/job.dart';
import '../shared/page_scaffold.dart';
import 'jobs_controller.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsControllerProvider);

    return PageScaffold(
      title: 'Jobs',
      subtitle: "Roles you're hiring for — tracked on this device",
      actions: [
        FilledButton.icon(
          onPressed: () => _showAddJobDialog(context, ref),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('+ New job'),
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.midnightNavy,
          ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Job Pipeline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Job Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(labelText: 'Company / Team'),
            ),
          ],
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
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref.read(jobsControllerProvider.notifier).addJob(
                      JobRole(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        company: companyController.text.isEmpty
                            ? 'Internal Team'
                            : companyController.text,
                        status: 'Open',
                        shortlisted: 0,
                        interviewing: 0,
                        offer: 0,
                        placed: 0,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isOpen
            ? AppPalette.softIceBlue.withAlpha(80)
            : AppPalette.midnightNavy.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.softIceBlue,
          width: 1,
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
                    color: AppPalette.midnightNavy,
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
            job.company,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (job.shortlisted > 0) ...[
                _StageDot(
                  color: AppPalette.oceanTeal,
                  label: '${job.shortlisted} shortlisted',
                ),
                const SizedBox(width: 12),
              ],
              if (job.interviewing > 0) ...[
                _StageDot(
                  color: AppPalette.warmGold,
                  label: '${job.interviewing} interviewing',
                ),
                const SizedBox(width: 12),
              ],
              if (job.offer > 0) ...[
                _StageDot(
                  color: AppPalette.vibrantAmber,
                  label: '${job.offer} offer',
                ),
                const SizedBox(width: 12),
              ],
              if (job.placed > 0) ...[
                _StageDot(
                  color: AppPalette.privacyEmerald,
                  label: '${job.placed} placed',
                ),
              ],
            ],
          ),
        ],
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
            color: AppPalette.midnightNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
