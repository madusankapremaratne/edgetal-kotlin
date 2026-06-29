import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/performance_metric.dart';
import '../shared/page_scaffold.dart';
import '../shared/stat_strip.dart';
import 'insights_controller.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final notifier = ref.read(insightsControllerProvider.notifier);

    return PageScaffold(
      title: 'Insights',
      subtitle: 'On-device performance — measured, not promised',
      actions: [
        if (state.metrics.isNotEmpty)
          IconButton(
            tooltip: 'Copy CSV',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: notifier.exportCsv()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Benchmark CSV copied')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined),
          ),
        if (state.metrics.isNotEmpty)
          IconButton(
            tooltip: 'Clear',
            onPressed: notifier.clear,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.running)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: state.metrics.isEmpty && !state.running
                ? EmptyState(
                    icon: Icons.insights_outlined,
                    title: 'No measurements yet',
                    message:
                        'Run the evaluation suite to benchmark on-device retrieval latency and precision.',
                    action: FilledButton.icon(
                      onPressed: notifier.runAutoBenchmark,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Run evaluation suite'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    children: [
                      StatStrip(items: [
                        StatItem(
                          label: 'Avg retrieval',
                          value: '${state.summary.avgRetrievalMs.toStringAsFixed(0)} ms',
                          icon: Icons.speed_outlined,
                        ),
                        StatItem(
                          label: 'Avg indexing',
                          value: '${state.summary.avgIngestionMs.toStringAsFixed(0)} ms',
                          icon: Icons.memory_outlined,
                        ),
                        StatItem(
                          label: 'Mean P@5',
                          value: state.summary.meanPrecision.toStringAsFixed(2),
                          icon: Icons.center_focus_strong_outlined,
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        color: context.colors.surfaceSubtle,
                        child: Row(
                          children: [
                            Icon(Icons.smartphone_outlined,
                                size: 18, color: context.colors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                state.summary.deviceInfo,
                                style: context.text.bodySmall,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed:
                                  state.running ? null : notifier.runAutoBenchmark,
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('Run suite'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'Recent measurements'),
                      const SizedBox(height: AppSpacing.md),
                      for (final m in state.metrics.reversed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _MetricRow(metric: m),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});
  final PerformanceMetric metric;

  @override
  Widget build(BuildContext context) {
    final slow = metric.durationMs > 1000;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.operationName,
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${metric.operationType} · P ${metric.precision.toStringAsFixed(2)} · ${formatTime(metric.timestamp)}',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${metric.durationMs} ms',
            style: context.text.titleSmall?.copyWith(
              color: slow ? context.scheme.error : context.colors.privacy,
            ),
          ),
        ],
      ),
    );
  }
}
