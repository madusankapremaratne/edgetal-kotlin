import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/resume.dart';
import '../shared/page_scaffold.dart';
import '../shared/stat_strip.dart';
import 'candidates_controller.dart';

class CandidatesScreen extends ConsumerWidget {
  const CandidatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(candidatesControllerProvider);
    final controller = ref.read(candidatesControllerProvider.notifier);
    // Kicks off the one-time embedder reconciliation (offline → on-device).
    ref.watch(startupReconcileProvider);

    return PageScaffold(
      title: 'Candidates',
      subtitle: 'Your private talent pool — stored only on this device',
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('/import'),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Import'),
        ),
      ],
      body: Builder(
        builder: (context) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: StatStrip(items: [
                    StatItem(
                      label: 'Candidates',
                      value: '${state.total}',
                      icon: Icons.groups_outlined,
                    ),
                    StatItem(
                      label: 'Indexed',
                      value: '${state.embeddedCount}',
                      icon: Icons.bolt_outlined,
                    ),
                    StatItem(
                      label: 'Vectors',
                      value: '${state.embeddingCount}',
                      icon: Icons.scatter_plot_outlined,
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: TextField(
                    onChanged: controller.setFilter,
                    decoration: const InputDecoration(
                      hintText: 'Filter by name, skill or role',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
              ),
              if (state.visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: state.resumes.isEmpty
                        ? 'No candidates yet'
                        : 'No matches',
                    message: state.resumes.isEmpty
                        ? 'Import a CSV of resumes to start building your private talent pool.'
                        : 'Try a different name, skill or role.',
                    action: state.resumes.isEmpty
                        ? FilledButton.icon(
                            onPressed: () => context.push('/import'),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Import resumes'),
                          )
                        : null,
                  ),
                )
              else
                SliverList.separated(
                  itemCount: state.visible.length,
                  itemBuilder: (context, i) {
                    final resume = state.visible[i];
                    return _CandidateCard(
                      resume: resume,
                      onTap: () => context.push('/candidate/${resume.id}'),
                      onDelete: () => _confirmDelete(context, controller, resume),
                    );
                  },
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CandidatesController controller,
    Resume resume,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove candidate?'),
        content: Text(
          'This permanently removes ${resume.fullName} and their vectors from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.delete(resume.id);
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.resume,
    required this.onTap,
    required this.onDelete,
  });

  final Resume resume;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final skills = resume.skillList.take(4).toList();
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Monogram(text: resume.initials, seed: resume.fullName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resume.fullName,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (resume.isEmbedded)
                      AppPill(
                        label: 'Indexed',
                        icon: Icons.check_circle_outline,
                        color: context.colors.privacy,
                        background: context.colors.privacySubtle,
                      ),
                  ],
                ),
                if (resume.category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(resume.category, style: context.text.bodySmall),
                ],
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in skills) AppPill(label: s),
                      if (resume.skillList.length > skills.length)
                        AppPill(
                          label: '+${resume.skillList.length - skills.length}',
                          color: context.colors.textMuted,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}
