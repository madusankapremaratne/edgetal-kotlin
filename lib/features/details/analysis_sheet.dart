import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/resume.dart';
import 'analysis_controller.dart';

/// Modal sheet that runs the on-device "fit analysis" agent for a candidate
/// against a pasted role description.
class AnalysisSheet {
  static Future<void> show(BuildContext context, Resume resume) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _AnalysisSheetBody(resume: resume),
    );
  }
}

class _AnalysisSheetBody extends ConsumerStatefulWidget {
  const _AnalysisSheetBody({required this.resume});
  final Resume resume;

  @override
  ConsumerState<_AnalysisSheetBody> createState() => _AnalysisSheetBodyState();
}

class _AnalysisSheetBodyState extends ConsumerState<_AnalysisSheetBody> {
  final _roleController = TextEditingController();
  static const _maxChars = 400;

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisControllerProvider);
    final notifier = ref.read(analysisControllerProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.borderStrong,
                  borderRadius: AppRadius.chip,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: context.colors.brand, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('AI fit analysis', style: context.text.titleMedium),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            Text('Candidate: ${widget.resume.fullName}',
                style: context.text.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            _Body(
              state: state,
              roleController: _roleController,
              maxChars: _maxChars,
              onRoleChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Actions(
              state: state,
              onAnalyse: () => notifier.analyze(widget.resume, _roleController.text),
              onReset: notifier.reset,
              canAnalyse: _roleController.text.trim().isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.roleController,
    required this.maxChars,
    required this.onRoleChanged,
  });

  final AnalysisState state;
  final TextEditingController roleController;
  final int maxChars;
  final VoidCallback onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: fadeThroughTransition,
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    if (state is AnalysisRunning) {
      return Column(
        key: const ValueKey('running'),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const LoadingDots(),
          const SizedBox(height: AppSpacing.lg),
          Text((state as AnalysisRunning).step,
              style: context.text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }
    if (state is AnalysisFailed) {
      return _Banner(
        key: const ValueKey('failed'),
        icon: Icons.error_outline,
        color: context.scheme.error,
        text: (state as AnalysisFailed).message,
      );
    }
    if (state is AnalysisDone) {
      final done = state as AnalysisDone;
      return Column(
        key: const ValueKey('done'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SourceBadge(onDevice: done.onDevice),
          const SizedBox(height: AppSpacing.lg),
          Text('REASONING',
              style: context.text.labelSmall
                  ?.copyWith(color: context.colors.brand)),
          const SizedBox(height: AppSpacing.sm),
          Text(done.reasoning, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: context.colors.privacySubtle,
            borderColor: context.colors.privacy.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOMMENDATION',
                    style: context.text.labelSmall
                        ?.copyWith(color: context.colors.onPrivacySubtle)),
                const SizedBox(height: AppSpacing.sm),
                Text(done.verdict, style: context.text.bodyLarge),
              ],
            ),
          ),
        ],
      );
    }
    // Idle
    return TextField(
      key: const ValueKey('idle'),
      controller: roleController,
      maxLines: 4,
      maxLength: maxChars,
      onChanged: (_) => onRoleChanged(),
      decoration: const InputDecoration(
        hintText:
            'Paste the role / requirements, e.g. “Senior backend engineer, '
            'Kafka, Kubernetes, leads a small team.”',
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.onDevice});
  final bool onDevice;

  @override
  Widget build(BuildContext context) {
    if (onDevice) {
      return AppPill(
        label: 'Generated by on-device Gemma',
        icon: Icons.verified_user_outlined,
        color: context.colors.privacy,
        background: context.colors.privacySubtle,
      );
    }
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.go('/models');
      },
      child: AppCard(
        color: context.colors.warningSubtle,
        borderColor: context.colors.warning.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: context.colors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Offline heuristic preview. Install the Gemma model for full '
                'on-device reasoning →',
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.onAnalyse,
    required this.onReset,
    required this.canAnalyse,
  });

  final AnalysisState state;
  final VoidCallback onAnalyse;
  final VoidCallback onReset;
  final bool canAnalyse;

  @override
  Widget build(BuildContext context) {
    if (state is AnalysisRunning) return const SizedBox.shrink();
    if (state is AnalysisDone || state is AnalysisFailed) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReset,
              child: const Text('New analysis'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      );
    }
    return FilledButton.icon(
      onPressed: canAnalyse ? onAnalyse : null,
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: const Text('Analyse fit'),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    );
  }
}
