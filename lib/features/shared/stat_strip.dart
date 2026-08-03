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

/// A single-row strip of compact metric tiles.
///
/// Always horizontal — sized so 2-3 tiles fit comfortably on a phone screen,
/// avoiding a previous stacked-column fallback whose default
/// [CrossAxisAlignment.center] shrank each card to its content width,
/// producing narrow, centered "islands" with dead space on either side.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _Tile(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final StatItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.brandSubtle,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppShadow.soft(context.colors.brand),
            ),
            child: Icon(item.icon, size: 16, color: context.colors.brand),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Fade+pop whenever the underlying value changes, so a stat that
          // updates (e.g. candidate count after an import) draws the eye
          // instead of silently jumping.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: fadeThroughTransition,
            child: Text(
              item.value,
              key: ValueKey(item.value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleLarge,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall,
          ),
        ],
      ),
    );
  }
}
