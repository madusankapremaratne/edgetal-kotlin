import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/page_scaffold.dart';
import 'import_controller.dart';

/// Whether folder import (local or cloud) is available on this platform.
bool get _folderImportAvailable => ImportController.isFolderImportSupported;

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

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await ref.read(importControllerProvider.notifier).importFromFolder(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider);
    final notifier = ref.read(importControllerProvider.notifier);

    ref.listen(importControllerProvider, (_, next) {
      if (next is ImportSuccess) {
        HapticFeedback.mediumImpact();
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          notifier.reset();
          if (router.canPop()) router.pop();
        });
      }
    });

    final busy = state is ImportLoading;
    final options = [
      if (_folderImportAvailable) 'From Folder',
      if (_folderImportAvailable) 'Cloud Folder',
      'CSV (File or Link)',
    ];
    final tab = _tab < options.length ? _tab : 0;

    return PageScaffold(
      title: 'Import resumes',
      subtitle: 'Parsed on-device — your candidates stay private',
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      scrollableBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Segmented(
            index: tab,
            onChanged: busy ? null : (i) => setState(() => _tab = i),
            options: options,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (options[tab] == 'From Folder')
            _FolderCard(busy: busy, onPick: _pickFolder)
          else if (options[tab] == 'Cloud Folder')
            _CloudFolderCard(busy: busy, onPick: _pickFolder)
          else
            _CsvCard(
              controller: _urlController,
              busy: busy,
              onPickFile: _pickFile,
              onImportUrl: () {
                FocusScope.of(context).unfocus();
                notifier.importFromUrl(_urlController.text);
              },
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: state is ImportIdle
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: fadeThroughTransition,
                      child: _StatusCard(
                        key: ValueKey(state.runtimeType),
                        state: state,
                        onDismiss: notifier.reset,
                      ),
                    ),
                  ),
          ),
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
                    textAlign: TextAlign.center,
                    style: context.text.labelMedium?.copyWith(
                      color: i == index
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                      fontWeight: i == index ? FontWeight.w600 : FontWeight.normal,
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

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.busy, required this.onPick});
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '1. Import from local folder',
            subtitle: 'Select a directory on this device containing PDF or DOCX resumes. '
                'The on-device AI reads each resume, extracts candidate data, and indexes profiles locally.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppGradientButton(
            onPressed: busy ? null : onPick,
            icon: Icons.folder_open_outlined,
            label: 'Choose local folder',
          ),
        ],
      ),
    );
  }
}

class _CloudFolderCard extends StatelessWidget {
  const _CloudFolderCard({required this.busy, required this.onPick});
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '2. Import from Cloud Folder',
            subtitle: 'Pick a folder from Google Drive, OneDrive, or iCloud Drive via your system file picker.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _CloudBadge(label: 'Google Drive', icon: Icons.add_to_drive),
              _CloudBadge(label: 'OneDrive', icon: Icons.cloud_outlined),
              _CloudBadge(label: 'iCloud Drive', icon: Icons.cloud_done_outlined),
              _CloudBadge(label: 'Dropbox', icon: Icons.folder_special_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppGradientButton(
            onPressed: busy ? null : onPick,
            icon: Icons.cloud_upload_outlined,
            label: 'Open Cloud Drive / Folder',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tip: In the system file picker, select your connected Google Drive or OneDrive from the side navigation menu.',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudBadge extends StatelessWidget {
  const _CloudBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceSubtle,
        borderRadius: AppRadius.chip,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.colors.brand),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvCard extends StatelessWidget {
  const _CsvCard({
    required this.controller,
    required this.busy,
    required this.onPickFile,
    required this.onImportUrl,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onPickFile;
  final VoidCallback onImportUrl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '3. Import CSV (File or Link)',
            subtitle: 'Import candidate datasets from a local CSV file or public URL link.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Local CSV File', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose a .csv or .txt file containing candidate data from this device.',
            style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: busy ? null : onPickFile,
            icon: const Icon(Icons.insert_drive_file_outlined, size: 20),
            label: const Text('Choose local CSV file'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: context.colors.border),
          const SizedBox(height: AppSpacing.md),
          Text('CSV Web Link (URL)', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter a publicly reachable web link pointing to a CSV file.',
            style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            enabled: !busy,
            decoration: const InputDecoration(
              hintText: 'https://example.com/resumes.csv',
              prefixIcon: Icon(Icons.link, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppGradientButton(
            onPressed: busy ? null : onImportUrl,
            icon: Icons.download_outlined,
            label: 'Import from URL',
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({super.key, required this.state, required this.onDismiss});
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
          Text('Supported import options', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1. Local Folder — PDF/DOCX resumes parsed on-device\n'
            '2. Cloud Folder — Google Drive, OneDrive, or iCloud Drive\n'
            '3. CSV Dataset — Local .csv file or remote web URL link',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 15, color: context.colors.privacy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Files are parsed locally. Candidate data never leaves this device.',
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
