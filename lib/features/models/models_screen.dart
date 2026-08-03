import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/llm/model_download_manager.dart';
import '../shared/page_scaffold.dart';
import 'models_controller.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  final _urlController =
      TextEditingController(text: ModelDownloadManager.defaultUrl);
  final _tokenController = TextEditingController();
  bool _advanced = false;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelsControllerProvider);
    final notifier = ref.read(modelsControllerProvider.notifier);

    return PageScaffold(
      title: 'On-device models',
      subtitle: 'Everything runs locally — download once, then stay offline',
      scrollableBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrivacyBanner(),
          const SizedBox(height: AppSpacing.lg),
          _ModelTile(
            title: 'Text embedder',
            subtitle: state.embedderLabel.isEmpty
                ? 'Semantic search engine'
                : state.embedderLabel,
            installed: true,
            statusLabel: state.embedderNative ? 'On-device' : 'Development',
            statusColor:
                state.embedderNative ? context.colors.privacy : context.colors.warning,
          ),
          const SizedBox(height: AppSpacing.lg),
          _LlmCard(
            state: state,
            onDownload: () => notifier.startDownload(
              url: _urlController.text,
              token: _tokenController.text,
            ),
            onCancel: notifier.cancel,
            onDelete: () => _confirmDelete(context, notifier, state.installedBytes),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BackendCard(state: state, onSelect: notifier.setLlmBackend),
          const SizedBox(height: AppSpacing.lg),
          _AdvancedCard(
            expanded: _advanced,
            onToggle: () => setState(() => _advanced = !_advanced),
            urlController: _urlController,
            tokenController: _tokenController,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ModelsController notifier,
    int bytes,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text(
          'This frees ${formatBytes(bytes)}. AI analysis will use the offline '
          'heuristic until the model is downloaded again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await notifier.deleteModel();
  }
}

class _PrivacyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.privacySubtle,
      borderColor: context.colors.privacy.withValues(alpha: 0.3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/logos/Icon Only.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EdgeTal Beta · 100% On-Device AI',
                      style: context.text.labelLarge?.copyWith(
                        color: context.colors.onPrivacySubtle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'GDPR by design: candidate data and AI inference never leave this '
                  'device. Models are downloaded once, then run fully offline.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onPrivacySubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.title,
    required this.subtitle,
    required this.installed,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final bool installed;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            installed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: installed ? context.colors.privacy : context.colors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          AppPill(
            label: statusLabel,
            color: statusColor,
            background: statusColor.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _LlmCard extends StatelessWidget {
  const _LlmCard({
    required this.state,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final ModelsState state;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final download = state.download;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isInstalled ? Icons.check_circle : Icons.warning_amber_rounded,
                color: state.isInstalled
                    ? context.colors.privacy
                    : context.colors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ModelDownloadManager.modelDisplayName,
                        style: context.text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      state.isInstalled
                          ? 'Installed · ${formatBytes(state.installedBytes)}'
                          : 'Not installed · powers AI candidate analysis',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: fadeThroughTransition,
            child: KeyedSubtree(
              key: ValueKey(download.runtimeType),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (download is Downloading)
                    _Progress(state: download, onCancel: onCancel)
                  else if (download is DownloadFailed) ...[
                    Text(download.message,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.scheme.error)),
                    if (!state.isInstalled) ...[
                      const SizedBox(height: AppSpacing.md),
                      _DownloadButton(state: state, onDownload: onDownload),
                    ],
                  ] else if (!state.isInstalled) ...[
                    Text(
                      'Download once over Wi-Fi (~1.3 GB). Everything runs on-device '
                      'afterwards — no data leaves your phone.',
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DownloadButton(state: state, onDownload: onDownload),
                  ],
                ],
              ),
            ),
          ),
          if (state.isInstalled) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.scheme.error,
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete model'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.state, required this.onDownload});
  final ModelsState state;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final resume = state.partialBytes > 0;
    final label = resume
        ? 'Resume download (${formatBytes(state.partialBytes)} done)'
        : 'Download model (~1.3 GB)';
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.download_outlined, size: 20),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: fadeThroughTransition,
          child: Text(label, key: ValueKey(label)),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state, required this.onCancel});
  final Downloading state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final hasTotal = state.totalBytes > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: hasTotal ? state.bytesDownloaded / state.totalBytes : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasTotal
              ? '${formatBytes(state.bytesDownloaded)} of ${formatBytes(state.totalBytes)} '
                  '(${state.percentage}%) · ${formatBytes(state.bytesPerSecond)}/s'
              : '${formatBytes(state.bytesDownloaded)} · ${formatBytes(state.bytesPerSecond)}/s',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.pause, size: 18),
          label: const Text('Pause'),
        ),
      ],
    );
  }
}

/// LLM inference backend (CPU/GPU) toggle — feeds the paper's resource
/// analysis GPU-delegation comparison. Embedding stays CPU-only (see
/// [NativeEmbeddingProvider]); this only switches the LLM channel.
class _BackendCard extends StatelessWidget {
  const _BackendCard({required this.state, required this.onSelect});

  final ModelsState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_board_outlined,
                  size: 18, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('LLM inference backend', style: context.text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'GPU delegation depends on the device SoC (e.g. Tensor G2) and can '
            'silently fall back to CPU — the badge below reflects what actually '
            'loaded, not just what was requested.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CPU', label: Text('CPU')),
                    ButtonSegment(value: 'GPU', label: Text('GPU')),
                  ],
                  selected: {state.llmBackend},
                  onSelectionChanged: state.switchingBackend
                      ? null
                      : (selection) => onSelect(selection.first),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (state.switchingBackend)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AppPill(
                  label: 'Active: ${state.llmBackend}',
                  color: context.colors.privacy,
                  background: context.colors.privacySubtle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvancedCard extends StatelessWidget {
  const _AdvancedCard({
    required this.expanded,
    required this.onToggle,
    required this.urlController,
    required this.tokenController,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController urlController;
  final TextEditingController tokenController;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text('Advanced: custom source',
                      style: context.text.titleSmall),
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    color: context.colors.textMuted),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Download from any direct URL (e.g. a Hugging Face “resolve” link). '
              'For gated repos, accept the licence and paste a read token.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Model URL'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: tokenController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Hugging Face token (optional)',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
