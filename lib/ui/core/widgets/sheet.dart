import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// Opens a Crudo-styled modal bottom sheet. Sheets are transient overlays —
/// deliberately NOT routes (architecture §5).
Future<T?> showCrudoSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Standard sheet layout: pill handle, optional kicker label, left-aligned
/// title, body, optional sticky CTA.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    required this.title,
    required this.body,
    this.label,
    this.cta,
    super.key,
  });

  final String title;

  /// Uppercase kicker above the title, e.g. "Commitment".
  final String? label;
  final Widget body;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(dim.Radii.lg),
        ),
        boxShadow: dim.Shadows.cloud,
      ),
      padding: const EdgeInsets.all(dim.Spacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, // grabber, 4px grid
                height: dim.Spacing.xs,
                decoration: BoxDecoration(
                  color: colors.surfaceHighest,
                  borderRadius: dim.Radii.all(dim.Radii.full),
                ),
              ),
            ),
            const SizedBox(height: dim.Spacing.md),
            if (label != null) ...[
              Text(label!.toUpperCase(), style: CrudoText.label),
              const SizedBox(height: dim.Spacing.xs),
            ],
            Text(title, style: CrudoText.headline),
            const SizedBox(height: dim.Spacing.md),
            Flexible(child: body),
            if (cta != null) ...[const SizedBox(height: dim.Spacing.lg), cta!],
          ],
        ),
      ),
    );
  }
}
