import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';

Future<void> showPaywallSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _PaywallSheet());

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return SheetScaffold(
      label: 'CRUDO PREMIUM',
      title: 'Keep your streak alive',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Monthly plan tile
          _PlanTile(
            label: 'Monthly',
            price: '€6.99/mo',
            isHighlighted: false,
            colors: colors,
          ),
          const SizedBox(height: dim.Spacing.sm),
          // Annual plan tile (highlighted)
          _PlanTile(
            label: 'Annual',
            price: '€39.99/yr',
            subPrice: '€3.33/mo',
            isHighlighted: true,
            colors: colors,
          ),
          const SizedBox(height: dim.Spacing.md),
          Text(
            '7-day free trial',
            textAlign: TextAlign.center,
            style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
          ),
        ],
      ),
      cta: PrimaryCta(
        label: 'Start free trial',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.label,
    required this.price,
    this.subPrice,
    required this.isHighlighted,
    required this.colors,
  });

  final String label;
  final String price;
  final String? subPrice;
  final bool isHighlighted;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(dim.Spacing.md),
      decoration: BoxDecoration(
        color: isHighlighted ? colors.goldSoft : colors.surfaceHigh,
        borderRadius: dim.Radii.all(dim.Radii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CrudoText.title.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: dim.Spacing.xs),
                Row(
                  children: [
                    Text(
                      price,
                      style: CrudoText.bodyLg.copyWith(
                        color: colors.onSurfaceVar,
                      ),
                    ),
                    if (subPrice != null) ...[
                      const SizedBox(width: dim.Spacing.sm),
                      Text(
                        '· $subPrice',
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: dim.Spacing.sm,
                vertical: dim.Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.gold,
                borderRadius: dim.Radii.all(dim.Radii.full),
              ),
              child: Text(
                'BEST VALUE',
                style: CrudoText.labelMd.copyWith(color: colors.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}
