import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Full-width primary action: 135° primary→primary-soft gradient, pill radius,
/// no shadow (design system). Disabled = half opacity + taps ignored.
class PrimaryCta extends StatelessWidget {
  const PrimaryCta({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: Container(
            key: const ValueKey('primary-cta-surface'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            decoration: BoxDecoration(
              borderRadius: Radii.all(Radii.full),
              gradient: LinearGradient(
                begin: Alignment.topLeft, // 135°
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primarySoft],
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CrudoText.title.copyWith(color: colors.surfaceLowest),
            ),
          ),
        ),
      ),
    );
  }
}
