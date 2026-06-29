import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/page_scaffold.dart';
import 'import_controller.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _urlController = TextEditingController();
  int _tab = 0;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(importControllerProvider.notifier).importFromFile(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider);
    final notifier = ref.read(importControllerProvider.notifier);

    ref.listen(importControllerProvider, (_, next) {
      if (next is ImportSuccess) {
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          notifier.reset();
          if (router.canPop()) router.pop();
        });
      }
    });

    final busy = state is ImportLoading;

    return PageScaffold(
      title: 'Import resumes',
      subtitle: 'CSV stays on this device — nothing is uploaded',
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      scrollableBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Segmented(
            index: _tab,
            onChanged: busy ? null : (i) => setState(() => _tab = i),
            options: const ['From URL', 'Local file'],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_tab == 0)
            _UrlCard(controller: _urlController, busy: busy, onImport: () {
              FocusScope.of(context).unfocus();
              notifier.importFromUrl(_urlController.text);
            })
          else
            _FileCard(busy: busy, onPick: _pickFile),
          if (state is! ImportIdle) ...[
            const SizedBox(height: AppSpacing.lg),
            _StatusCard(state: state, onDismiss: notifier.reset),
          ],
          const SizedBox(height: AppSpacing.lg),
          _ReindexCard(busy: busy, onRun: notifier.generateEmbeddings),
          const SizedBox(height: AppSpacing.lg),
          const _FormatsCard(),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.index,
    required this.options,
    required this.onChanged,
  });

  final int index;
  final List<String> options;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceSubtle,
        borderRadius: AppRadius.field,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? context.scheme.surface : Colors.transparent,
                    borderRadius: AppRadius.card,
                    border: Border.all(
                      color: i == index
                          ? context.colors.border
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    options[i],
                    style: context.text.labelLarge?.copyWith(
                      color: i == index
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UrlCard extends StatelessWidget {
  const _UrlCard({
    required this.controller,
    required this.busy,
    required this.onImport,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Import from a URL',
            subtitle: 'Point to a publicly reachable .csv file',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            enabled: !busy,
            decoration: const InputDecoration(
              hintText: 'https://example.com/resumes.csv',
              prefixIcon: Icon(Icons.link, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: busy ? null : onImport,
            icon: const Icon(Icons.download_outlined, size: 20),
            label: const Text('Import from URL'),
          ),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.busy, required this.onPick});
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Import a local file',
            subtitle: 'Choose a CSV from this device',
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: busy ? null : onPick,
            icon: const Icon(Icons.folder_open_outlined, size: 20),
            label: const Text('Choose CSV file'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.onDismiss});
  final ImportUiState state;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (state is ImportLoading) {
      final s = state as ImportLoading;
      return AppCard(
        color: context.colors.brandSubtle,
        borderColor: context.colors.brand.withValues(alpha: 0.3),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: s.progress,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(s.message, style: context.text.bodyMedium)),
          ],
        ),
      );
    }
    if (state is ImportSuccess) {
      return _Banner(
        icon: Icons.check_circle_outline,
        color: context.colors.privacy,
        background: context.colors.privacySubtle,
        title: 'Import complete',
        message: (state as ImportSuccess).message,
      );
    }
    final err = state as ImportError;
    return _Banner(
      icon: Icons.error_outline,
      color: context.scheme.error,
      background: context.scheme.errorContainer,
      title: 'Import failed',
      message: err.message,
      onDismiss: onDismiss,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: background,
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(message, style: context.text.bodySmall),
              ],
            ),
          ),
          if (onDismiss != null)
            TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
        ],
      ),
    );
  }
}

class _ReindexCard extends StatelessWidget {
  const _ReindexCard({required this.busy, required this.onRun});
  final bool busy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Re-index embeddings',
            subtitle: 'Regenerate on-device vectors for semantic search',
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: busy ? null : onRun,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Generate embeddings'),
          ),
        ],
      ),
    );
  }
}

class _FormatsCard extends StatelessWidget {
  const _FormatsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.surfaceSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Supported formats', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• Kaggle Resume Dataset (9 columns)\n'
            '• Extended Resume Dataset (35 columns)\n'
            '• Custom CSV with a header row (auto-detected)',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 15, color: context.colors.privacy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Files are parsed locally. Nothing is sent to a server.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.privacy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
