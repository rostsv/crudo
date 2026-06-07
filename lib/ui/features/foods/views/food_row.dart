import 'package:flutter/material.dart';

import '../../../../domain/food/food.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import 'formatting.dart';

/// Library list row: name + per-100g summary. Custom foods get a marker
/// pill and (when [onTap] is set) navigate to edit; seed rows are inert
/// until S08's picker gives them a tap meaning.
class FoodRow extends StatelessWidget {
  const FoodRow({required this.food, this.onTap, super.key});

  final Food food;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.sm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            food.name,
                            style: CrudoText.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (food.isCustom) ...[
                          const SizedBox(width: Spacing.sm),
                          Container(
                            key: const ValueKey('custom-pill'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: Spacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: Radii.all(Radii.full),
                            ),
                            child: Text(
                              'CUSTOM',
                              style: CrudoText.label.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      foodSummary(food),
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: IconSizes.md,
                  color: colors.onSurfaceMut,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "165 kcal · P31 C0 F3.6" — kcal rounded for display (stored value stays
/// unrounded), grams trimmed of trailing .0.
String foodSummary(Food f) =>
    '${f.kcalPer100g.round()} kcal · '
    'P${gramsText(f.protein)} C${gramsText(f.carbs)} F${gramsText(f.fats)}';
