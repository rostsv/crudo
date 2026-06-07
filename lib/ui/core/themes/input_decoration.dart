import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimensions.dart';
import 'typography.dart';

/// Soft-filled input decoration used across form fields (S07).
///
/// Fills with [colors.surfaceLow], no border, rounded corners at [radius]
/// (default [Radii.sm]). Pass [hint] and [hintStyle] to configure the
/// placeholder; pass [prefixIcon] for leading icons (e.g. search).
///
/// The kcal-override field inside [KcalCard] intentionally uses an inline
/// underline/borderless decoration — it is a deliberate departure from this
/// soft style because it lives inside a filled card and needs no box.
InputDecoration softInputDecoration(
  CrudoColors colors, {
  String? hint,
  TextStyle? hintStyle,
  Widget? prefixIcon,
  double radius = Radii.sm,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
    horizontal: Spacing.sm,
    vertical: Spacing.sm,
  ),
  bool isDense = false,
}) {
  return InputDecoration(
    filled: true,
    fillColor: colors.surfaceLow,
    hintText: hint,
    hintStyle: hintStyle ?? CrudoText.body.copyWith(color: colors.onSurfaceMut),
    prefixIcon: prefixIcon,
    isDense: isDense,
    contentPadding: contentPadding,
    border: OutlineInputBorder(
      borderRadius: Radii.all(radius),
      borderSide: BorderSide.none,
    ),
  );
}
