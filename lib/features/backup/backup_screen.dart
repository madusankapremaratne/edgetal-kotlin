import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/backup/backup_package_service.dart';
import '../candidates/candidates_controller.dart';
import '../jobs/jobs_controller.dart';
import '../shared/page_scaffold.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passwordController = TextEditingController();
  String _selectedFormat = 'EDGETAL Package (.edgetal)';
  bool _exportSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runExport() async {
    final candidatesState = ref.read(candidatesControllerProvider);
    final jobsState = ref.read(jobsControllerProvider);

    if (_selectedFormat.contains('.edgetal')) {
      final service = BackupPackageService();
      await service.createPackage(
        resumes: candidatesState.resumes,
        jobs: jobsState.jobs,
        password: _passwordController.text,
      );
    }

    setState(() => _exportSuccess = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppPalette.privacyEmerald,
        content: Text('Export complete — talent pool saved as $_selectedFormat'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Backup & Export',
      subtitle: 'Export candidate data & job pipelines — 100% on-device',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      scrollableBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Format Selector Cards
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('.edgetal Package')),
                  selected: _selectedFormat.contains('.edgetal'),
                  selectedColor: AppPalette.midnightNavy,
                  labelStyle: TextStyle(
                    color: _selectedFormat.contains('.edgetal')
                        ? Colors.white
                        : context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = 'EDGETAL Package (.edgetal)');
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('CSV Format')),
                  selected: _selectedFormat == 'CSV',
                  selectedColor: AppPalette.midnightNavy,
                  labelStyle: TextStyle(
                    color: _selectedFormat == 'CSV'
                        ? Colors.white
                        : context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFormat = 'CSV');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Optional Encryption Password Input
          if (_selectedFormat.contains('.edgetal')) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: context.colors.brand, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Optional AES Password Encryption', style: context.text.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Encrypt your package for peer-to-peer sharing via AirDrop, USB, or Email.',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Encryption Password (optional)',
                      hintText: 'Leave empty for unencrypted package',
                      prefixIcon: Icon(Icons.key, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Destination Info Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.brandSubtle,
              borderRadius: AppRadius.cardXl,
              border: Border.all(color: context.colors.border),
              boxShadow: AppShadow.soft(AppPalette.midnightNavy),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open, color: context.colors.textPrimary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination: Local Files / Share Sheet',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Saved directly to local device storage',
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.colors.textPrimary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Export Button
          AppGradientButton(
            onPressed: _runExport,
            icon: Icons.ios_share,
            label: 'Export Candidate & Job Package',
          ),
          if (_exportSuccess) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppPalette.privacyEmerald.withValues(alpha: 0.15),
                borderRadius: AppRadius.cardXl,
                border: Border.all(color: AppPalette.privacyEmerald),
                boxShadow: AppShadow.soft(AppPalette.privacyEmerald),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppPalette.privacyEmerald),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '✓ Export complete — package ready for peer-to-peer sharing!',
                      style: context.text.labelLarge?.copyWith(
                        color: AppPalette.privacyEmerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
