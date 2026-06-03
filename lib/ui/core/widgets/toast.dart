import 'dart:async';

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// Toast severity — picks the accent color and leading icon.
enum ToastKind { success, warn, error }

/// Floating banner toast (dark surface, accent edge, auto-dismiss): a bold
/// [title], optional [body] detail, and a dismiss X. For inline validation
/// feedback prefer in-form errors; toasts are for global events.
void showCrudoToast(
  BuildContext context,
  String title, {
  String? body,
  ToastKind kind = ToastKind.success,
  Duration duration = const Duration(milliseconds: 4500),
}) {
  final overlay = Overlay.of(context);
  final colors = Theme.of(context).extension<CrudoColors>()!;
  final (accent, icon) = switch (kind) {
    ToastKind.success => (colors.primarySoft, Icons.check),
    ToastKind.warn => (colors.gold, Icons.warning_amber),
    ToastKind.error => (colors.error, Icons.warning_amber),
  };

  late final OverlayEntry entry;
  late final Timer timer;
  void dismiss() {
    timer.cancel();
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 2 * dim.Spacing.xxl,
      left: dim.Spacing.md,
      right: dim.Spacing.md,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(dim.Spacing.md),
          decoration: BoxDecoration(
            color: colors.onSurface,
            borderRadius: dim.Radii.all(dim.Radii.md),
            boxShadow: dim.Shadows.cloudDeep,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent edge as a filled bar (no-line rule: never a Border).
              Container(
                width: dim.Spacing.xs,
                height: dim.IconSizes.md,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: dim.Radii.all(dim.Radii.full),
                ),
              ),
              const SizedBox(width: dim.Spacing.sm),
              Icon(icon, size: dim.IconSizes.md, color: colors.surfaceLowest),
              const SizedBox(width: dim.Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CrudoText.body.copyWith(
                        color: colors.surfaceLowest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: dim.Spacing.xs),
                      Text(
                        body,
                        style: CrudoText.body.copyWith(
                          color: colors.surfaceLowest.withValues(alpha: 0.75),
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
                  color: colors.surfaceLowest.withValues(alpha: 0.7),
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
