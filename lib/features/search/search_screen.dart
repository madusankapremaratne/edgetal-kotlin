import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/page_scaffold.dart';
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

  void _run() {
    FocusScope.of(context).unfocus();
    ref.read(searchControllerProvider.notifier).search(_controller.text);
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
                child: FilledButton.icon(
                  onPressed: _controller.text.trim().isEmpty ? null : _run,
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Search'),
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
          const SizedBox(height: AppSpacing.lg),
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
    final state = model.state;
    if (state is SearchIdle) {
      return _Examples(onPick: onPickExample);
    }
    if (state is SearchLoading) {
      return const _Centered(child: CircularProgressIndicator());
    }
    if (state is SearchAgenticLoading) {
      return _Centered(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(state.step, style: context.text.bodyMedium),
          ],
        ),
      );
    }
    if (state is SearchError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Search unavailable',
        message: state.message,
      );
    }
    final success = state as SearchSuccess;
    if (success.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No close matches',
        message: 'Try AI assist to broaden the query automatically.',
        action: FilledButton.icon(
          onPressed: () =>
              ref.read(searchControllerProvider.notifier).agenticSearch(model.query),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('AI assist'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        _ResultMeta(model: model, success: success),
        const SizedBox(height: AppSpacing.lg),
        for (final r in success.results) ...[
          _ResultCard(result: r),
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
    return AppPill(label: '$pct% match', color: color, background: bg);
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
  const _Examples({required this.onPick});
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
        for (final e in _SearchScreenState._examples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => onPick(e),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.north_east,
                      size: 16, color: context.colors.textMuted),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(e, style: context.text.bodyMedium)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(child: child);
}
