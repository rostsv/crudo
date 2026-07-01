import 'dart:async';

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// Toast severity — picks the accent color, tint, and leading icon.
enum ToastKind { success, warn, error }

/// Top-anchored banner toast with a tinted background, filled icon badge,
/// bold title, optional body, and a dismiss X.
/// For inline validation feedback prefer in-form errors; toasts are for global
/// events.
void showCrudoToast(
  BuildContext context,
  String title, {
  String? body,
  ToastKind kind = ToastKind.success,
  Duration duration = const Duration(milliseconds: 4500),
}) {
  final overlay = Overlay.of(context);
  final colors = Theme.of(context).extension<CrudoColors>()!;
  final (accent, tint, badgeIcon) = switch (kind) {
    ToastKind.success => (colors.success, colors.primaryContainer, Icons.check),
    ToastKind.warn => (colors.gold, colors.goldSoft, Icons.priority_high),
    ToastKind.error => (colors.error, colors.errorSoft, Icons.close),
  };

  late final OverlayEntry entry;
  late final Timer timer;
  void dismiss() {
    timer.cancel();
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + dim.Spacing.sm,
      left: dim.Spacing.md,
      right: dim.Spacing.md,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: dim.Radii.all(dim.Radii.lg),
            boxShadow: dim.Shadows.cloudDeep,
          ),
          padding: const EdgeInsets.all(dim.Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
                padding: const EdgeInsets.all(dim.Spacing.xs),
                child: Icon(
                  badgeIcon,
                  size: dim.IconSizes.md,
                  color: colors.surfaceLowest,
                ),
              ),
              const SizedBox(width: dim.Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CrudoText.body.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: dim.Spacing.xs),
                      Text(
                        body,
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: dim.Spacing.sm),
              GestureDetector(
                key: const ValueKey('toast-dismiss'),
                onTap: dismiss,
                child: Icon(
                  Icons.close,
                  size: dim.IconSizes.sm,
                  color: colors.onSurfaceMut,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  timer = Timer(duration, dismiss);
}
