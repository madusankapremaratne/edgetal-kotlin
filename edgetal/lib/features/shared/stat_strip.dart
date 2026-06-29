import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';

class StatItem {
  const StatItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
}

/// A responsive row of small metric tiles.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;
        final tiles = [
          for (final item in items)
            stacked
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _Tile(item: item),
                  )
                : Expanded(child: _Tile(item: item)),
        ];
        if (stacked) {
          return Column(children: tiles);
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i != tiles.length - 1) const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final StatItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 20, color: context.colors.brand),
          const SizedBox(height: AppSpacing.md),
          Text(item.value, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(item.label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}
