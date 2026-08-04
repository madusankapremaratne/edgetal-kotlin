import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/performance_metric.dart';
import '../candidates/candidates_controller.dart';
import '../jobs/jobs_controller.dart';
import '../shared/page_scaffold.dart';
import '../shared/stat_strip.dart';
import 'insights_controller.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final notifier = ref.read(insightsControllerProvider.notifier);
    final candidatesState = ref.watch(candidatesControllerProvider);
    final jobsState = ref.watch(jobsControllerProvider);

    return PageScaffold(
      title: 'Insights',
      subtitle: 'On-device talent analytics & performance benchmarks',
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
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                _TalentPoolInsightsSection(
                  candidateCount: candidatesState.resumes.length,
                  jobCount: jobsState.jobs.length,
                  skills: candidatesState.resumes
                      .expand((r) => r.skillList)
                      .toSet()
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ResourceProfileSection(state: state, notifier: notifier),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Retrieval benchmark'),
                const SizedBox(height: AppSpacing.md),
                if (state.metrics.isEmpty && !state.running)
                  EmptyState(
                    icon: Icons.insights_outlined,
                    title: 'No measurements yet',
                    message:
                        'Run the evaluation suite to benchmark on-device retrieval latency and precision.',
                    action: AppGradientButton(
                      onPressed: notifier.runAutoBenchmark,
                      icon: Icons.play_arrow_rounded,
                      label: 'Run evaluation suite',
                    ),
                  )
                else ...[
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
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Recent measurements'),
                  const SizedBox(height: AppSpacing.md),
                  for (final (i, m) in state.metrics.reversed.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: StaggeredEntrance(
                        index: i,
                        child: _MetricRow(metric: m),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Computational resource analysis" section — sustained-load profiling
/// (memory / battery / CPU / thermal) across the full on-device pipeline.
class _ResourceProfileSection extends StatelessWidget {
  const _ResourceProfileSection({required this.state, required this.notifier});

  final InsightsState state;
  final InsightsController notifier;

  @override
  Widget build(BuildContext context) {
    final summary = state.profileSummary;
    final (completed, total) = state.profileProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Computational resource analysis',
          subtitle: 'Full pipeline (embed → search → LLM) under sustained load',
          trailing: (summary.hasData || state.resourceSamples.isNotEmpty) &&
                  !state.profiling
              ? IconButton(
                  tooltip: 'Clear resource samples',
                  onPressed: notifier.clearResourceSamples,
                  icon: const Icon(Icons.delete_outline),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: context.colors.surfaceSubtle,
          child: Text(
            'Samples memory, battery, CPU and thermal state every 2s while the '
            'full retrieval+generation pipeline runs back-to-back. Run once per '
            'device (e.g. Pixel 7 Pro, Redmi Note 7) with the screen on and '
            'unplugged for a true battery-drain reading. Thermal status reads '
            '"UNSUPPORTED" below Android 10 (API 29). Embedding runs CPU-only; '
            'the LLM backend (CPU/GPU) is set on the Models screen.',
            style: context.text.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.profiling) ...[
          LinearProgressIndicator(
            value: total > 0 ? completed / total : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Query $completed/$total…',
            style: context.text.bodySmall,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.runSustainedProfile(totalQueries: 10),
                  icon: const Icon(Icons.bolt_outlined, size: 18),
                  label: const Text('Quick profile (10)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => notifier.runSustainedProfile(totalQueries: 60),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Full profile (60)'),
                ),
              ),
            ],
          ),
        if (summary.hasData) ...[
          const SizedBox(height: AppSpacing.lg),
          StatStrip(items: [
            StatItem(
              label: 'Peak RAM',
              value: '${summary.peakMemMb.toStringAsFixed(0)} MB',
              icon: Icons.memory_outlined,
            ),
            StatItem(
              label: 'Avg RAM',
              value: '${summary.avgMemMb.toStringAsFixed(0)} MB',
              icon: Icons.memory_outlined,
            ),
            StatItem(
              label: 'Battery drained',
              value: '${summary.batteryPctDrained.toStringAsFixed(0)}%',
              icon: Icons.battery_full_outlined,
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          StatStrip(items: [
            StatItem(
              label: 'Avg CPU',
              value: '${summary.avgCpuPct.toStringAsFixed(0)}%',
              icon: Icons.speed_outlined,
            ),
            StatItem(
              label: 'Peak CPU',
              value: '${summary.peakCpuPct.toStringAsFixed(0)}%',
              icon: Icons.speed_outlined,
            ),
            StatItem(
              label: 'Thermal',
              value: summary.throttled ? '${summary.maxThermalStatus} ⚠' : summary.maxThermalStatus,
              icon: Icons.thermostat_outlined,
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(summary.summaryText, style: context.text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: notifier.exportResourceCsv()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Resource CSV copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        label: const Text('Copy CSV'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: summary.summaryText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Summary copied')),
                          );
                        },
                        icon: const Icon(Icons.content_copy_outlined, size: 18),
                        label: const Text('Copy summary'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TalentPoolInsightsSection extends StatelessWidget {
  const _TalentPoolInsightsSection({
    required this.candidateCount,
    required this.jobCount,
    required this.skills,
  });

  final int candidateCount;
  final int jobCount;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Talent pool & competency matrix',
          subtitle: 'Calculated 100% on-device from your private resume vault',
        ),
        const SizedBox(height: AppSpacing.md),
        StatStrip(items: [
          StatItem(
            label: 'Indexed resumes',
            value: '$candidateCount',
            icon: Icons.people_outline,
          ),
          StatItem(
            label: 'Active jobs',
            value: '$jobCount',
            icon: Icons.work_outline,
          ),
          StatItem(
            label: 'Unique skills',
            value: '${skills.length}',
            icon: Icons.auto_awesome_outlined,
          ),
        ]),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Extracted Competency Index', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final skill in skills.take(12))
                      AppPill(
                        label: skill,
                        color: context.colors.brand,
                        background: context.colors.brandSubtle,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
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
