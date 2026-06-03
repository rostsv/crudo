import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// Tappable option card. Selection = surface-tone shift (no border, ever).
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: dim.Durations.fast,
          padding: const EdgeInsets.all(dim.Spacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceLowest,
            borderRadius: dim.Radii.all(dim.Radii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CrudoText.title),
                    if (subtitle != null) ...[
                      const SizedBox(height: dim.Spacing.xs),
                      Text(
                        subtitle!,
                        style: CrudoText.label.copyWith(
                          color: colors.onSurfaceVar,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
