import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';

/// End-of-day encouragement strip (today only). Tonal — surfaceLow on
/// surface, no shadow, no border.
class NudgeCard extends StatelessWidget {
  const NudgeCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  static const _iconCircle = 40.0; // component size, 4px grid

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: _iconCircle,
            height: _iconCircle,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: IconSizes.md,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(body, style: CrudoText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
