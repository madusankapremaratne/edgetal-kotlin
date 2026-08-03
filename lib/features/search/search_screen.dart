import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/page_scaffold.dart';
import 'account_gate_modal.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  static const _examples = [
    'Backend engineer who knows Kafka and Kubernetes',
    'Designer focused on accessibility',
    'Someone who can lead a team and ship on cadence',
    'Privacy-minded ML engineer',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    FocusScope.of(context).unfocus();
    final currentCount = ref.read(searchControllerProvider).searchCount;
    await ref.read(searchControllerProvider.notifier).search(_controller.text);
    if (currentCount >= 2 && mounted) {
      AccountGateModal.show(
        context,
        onContinue: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account creation flow initialized')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    return PageScaffold(
      title: 'Semantic search',
      subtitle: 'Describe the person you need — in plain language',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _run(),
            decoration: InputDecoration(
              hintText: 'e.g. “Find a product designer who knows Figma”',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        notifier.clear();
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppGradientButton(
                  onPressed: _controller.text.trim().isEmpty ? null : _run,
                  icon: Icons.search,
                  label: 'Search',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _controller.text.trim().isEmpty
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        notifier.agenticSearch(_controller.text);
                      },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('AI assist'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(child: _Results(model: model, onPickExample: (e) {
            _controller.text = e;
            setState(() {});
            _run();
          })),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.model, required this.onPickExample});

  final SearchModel model;
  final void Function(String) onPickExample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: fadeThroughTransition,
      child: _build(context, ref),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final state = model.state;
    if (state is SearchIdle) {
      return _Examples(key: const ValueKey('idle'), onPick: onPickExample);
    }
    if (state is SearchLoading) {
      return const _Centered(key: ValueKey('loading'), child: LoadingDots());
    }
    if (state is SearchAgenticLoading) {
      return _Centered(
        key: const ValueKey('agentic'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingDots(),
            const SizedBox(height: AppSpacing.lg),
            Text(state.step, style: context.text.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (state is SearchError) {
      return EmptyState(
        key: const ValueKey('error'),
        icon: Icons.error_outline,
        title: 'Search unavailable',
        message: state.message,
      );
    }
    final success = state as SearchSuccess;
    if (success.results.isEmpty) {
      return EmptyState(
        key: const ValueKey('no-results'),
        icon: Icons.search_off_outlined,
        title: 'No close matches',
        message: 'Try AI assist to broaden the query automatically.',
        action: AppGradientButton(
          onPressed: () =>
              ref.read(searchControllerProvider.notifier).agenticSearch(model.query),
          icon: Icons.auto_awesome,
          label: 'AI assist',
        ),
      );
    }

    return ListView(
      key: ValueKey('results-${model.query}-${success.results.length}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        _ResultMeta(model: model, success: success),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < success.results.length; i++) ...[
          StaggeredEntrance(index: i, child: _ResultCard(result: success.results[i])),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        _Feedback(),
      ],
    );
  }
}

class _ResultMeta extends StatelessWidget {
  const _ResultMeta({required this.model, required this.success});
  final SearchModel model;
  final SearchSuccess success;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: success.reformulatedQuery != null
          ? context.colors.brandSubtle
          : context.colors.surfaceSubtle,
      borderColor: success.reformulatedQuery != null
          ? context.colors.brand.withValues(alpha: 0.3)
          : context.colors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined,
                  size: 16, color: context.colors.textSecondary),
              const SizedBox(width: 6),
              Text('${model.resultCount} matches',
                  style: context.text.labelMedium),
              const Spacer(),
              Text('${model.executionMs} ms on-device',
                  style: context.text.labelSmall),
            ],
          ),
          if (success.reformulatedQuery != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'AI refined your query to: “${success.reformulatedQuery}”',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onBrandSubtle),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final SearchResultUi result;

  @override
  Widget build(BuildContext context) {
    final pct = (result.result.similarityScore * 100).round();
    final resume = result.resume;
    return AppCard(
      onTap: resume == null
          ? null
          : () => context.push(
                '/candidate/${resume.id}?q=${Uri.encodeComponent(result.result.segmentText)}',
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  resume?.fullName ?? 'Unknown candidate',
                  style: context.text.titleSmall,
                ),
              ),
              _MatchBadge(pct: pct),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPill(
            label: 'Matched in ${_titleCase(result.result.segmentType)}',
            color: context.colors.onBrandSubtle,
            background: context.colors.brandSubtle,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            result.result.segmentText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.pct});
  final int pct;

  @override
  Widget build(BuildContext context) {
    final strong = pct >= 60;
    final color = strong ? context.colors.privacy : context.colors.warning;
    final bg = strong ? context.colors.privacySubtle : context.colors.warningSubtle;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: AppPill(label: '$pct% match', color: color, background: bg),
    );
  }
}

class _Feedback extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchControllerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Were these helpful?', style: context.text.bodySmall),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(
          onPressed: () => notifier.recordFeedback(true),
          child: const Text('Yes'),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: () => notifier.recordFeedback(false),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Refine with AI'),
        ),
      ],
    );
  }
}

class _Examples extends StatelessWidget {
  const _Examples({super.key, required this.onPick});
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: context.colors.privacy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Every search runs on this device. No resume text is ever uploaded.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.privacy),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Try a search', style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < _SearchScreenState._examples.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: StaggeredEntrance(
              index: i,
              child: AppCard(
                onTap: () => onPick(_SearchScreenState._examples[i]),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.north_east,
                        size: 16, color: context.colors.textMuted),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(_SearchScreenState._examples[i],
                          style: context.text.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(child: child);
}
