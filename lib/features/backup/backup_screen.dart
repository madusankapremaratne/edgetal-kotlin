import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/page_scaffold.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String _selectedFormat = 'CSV';
  bool _exportSuccess = false;

  void _runExport() {
    setState(() => _exportSuccess = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppPalette.privacyEmerald,
        content: Text('Export complete — candidate pool saved as $_selectedFormat'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Backup & Export',
      subtitle: 'Export your candidate data — no cloud involved',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      scrollableBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Format Selector
          Row(
            children: [
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('JSON Format')),
                  selected: _selectedFormat == 'JSON',
                  selectedColor: AppPalette.midnightNavy,
                  labelStyle: TextStyle(
                    color: _selectedFormat == 'JSON'
                        ? Colors.white
                        : context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFormat = 'JSON');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
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
                        'Destination: Local Device Storage',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Files app / Downloads folder',
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
            label: 'Export All Candidate Data',
          ),
          if (_exportSuccess) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppPalette.privacyEmerald.withAlpha(30),
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
                      '✓ Export complete — saved to local Files',
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
