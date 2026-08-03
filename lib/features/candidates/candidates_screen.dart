import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_palette.dart';
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: fadeThroughTransition,
        child: state.loading
            ? const Center(key: ValueKey('loading'), child: LoadingDots())
            : _CandidatesList(
                key: const ValueKey('content'),
                state: state,
                controller: controller,
              ),
      ),
    );
  }
}

class _CandidatesList extends StatelessWidget {
  const _CandidatesList({super.key, required this.state, required this.controller});

  final CandidatesState state;
  final CandidatesController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Hero Banner (Page 6 Spec)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [AppPalette.midnightNavy, Color(0xFF1E3A52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.midnightNavy.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/logos/Icon Only.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EdgeTal',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Screen smarter. Stay private.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.total} candidates ready to search',
                      style: const TextStyle(
                        color: AppPalette.oceanTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 2x2 Card Grid (Page 7 Spec)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppPalette.softIceBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.total}',
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.midnightNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.groups,
                                    size: 16, color: AppPalette.midnightNavy),
                                const SizedBox(width: 4),
                                Text('Candidates',
                                    style: context.text.labelSmall?.copyWith(
                                        color: AppPalette.midnightNavy)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppPalette.warmGold,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.embeddedCount}',
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.midnightNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.bolt,
                                    size: 16, color: AppPalette.midnightNavy),
                                const SizedBox(width: 4),
                                Text('Indexed',
                                    style: context.text.labelSmall?.copyWith(
                                        color: AppPalette.midnightNavy)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppPalette.oceanTeal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3',
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('Shortlisted',
                                    style: context.text.labelSmall
                                        ?.copyWith(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppPalette.midnightNavy,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '18ms',
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.midnightNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.speed,
                                    size: 16, color: AppPalette.midnightNavy),
                                const SizedBox(width: 4),
                                Text('Benchmarks',
                                    style: context.text.labelSmall?.copyWith(
                                        color: AppPalette.midnightNavy)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              title: state.resumes.isEmpty ? 'No candidates yet' : 'No matches',
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
              return StaggeredEntrance(
                index: i,
                child: _CandidateCard(
                  resume: resume,
                  onTap: () => context.push('/candidate/${resume.id}'),
                  onDelete: () => _confirmDelete(context, controller, resume),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          ),
      ],
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
        icon: Icon(Icons.delete_outline, color: context.scheme.error),
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
    if (ok == true) {
      await controller.delete(resume.id);
      if (context.mounted) HapticFeedback.mediumImpact();
    }
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
          Hero(
            tag: 'avatar-${resume.id}',
            child: Monogram(text: resume.initials, seed: resume.fullName),
          ),
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
