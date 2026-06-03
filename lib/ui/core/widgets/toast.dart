import 'dart:async';

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// Floating confirmation toast (Cloud Shadow, auto-dismiss). For inline
/// validation feedback prefer in-form errors; toasts are for global events.
void showCrudoToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final colors = Theme.of(context).extension<CrudoColors>()!;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 96,
      left: dim.Spacing.lg,
      right: dim.Spacing.lg,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: dim.Spacing.md,
              vertical: dim.Spacing.sm + dim.Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceLowest,
              borderRadius: dim.Radii.all(dim.Radii.md),
              boxShadow: dim.Shadows.cloud,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: CrudoText.labelMd.copyWith(color: colors.onSurface),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 2500), entry.remove);
}
