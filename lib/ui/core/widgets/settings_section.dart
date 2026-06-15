import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// A titled section card for settings. [title] is rendered as an uppercase
/// kicker label, and [children] are wrapped in a `surfaceLowest` card with
/// `Radii.lg` and separated by vertical padding (no dividers).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CrudoText.label),
        const SizedBox(height: dim.Spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: dim.Radii.all(dim.Radii.lg),
          ),
          padding: const EdgeInsets.all(dim.Spacing.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ],
    );
  }
}

/// A tappable row within a settings list. [label] is the primary text,
/// [subtitle] is muted secondary text below it. When [trailing] is null and
/// [onTap] is non-null, a right chevron is shown automatically.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final effectiveTrailing =
        trailing ??
        (onTap != null
            ? Icon(
                Icons.chevron_right,
                size: dim.IconSizes.md,
                color: colors.onSurfaceMut,
              )
            : null);

    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        highlightColor: colors.surfaceLow,
        splashColor: Colors.transparent,
        borderRadius: dim.Radii.all(dim.Radii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: dim.Spacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: CrudoText.bodyLg.copyWith(color: colors.onSurface),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: dim.Spacing.xs),
                      Text(subtitle!, style: CrudoText.body),
                    ],
                  ],
                ),
              ),
              if (effectiveTrailing != null) ...[
                const SizedBox(width: dim.Spacing.sm),
                effectiveTrailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
