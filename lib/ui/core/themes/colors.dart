import 'package:flutter/material.dart';

abstract final class CrudoPalette {
  static const surface = Color(0xFFFAF9F6);
  static const surfaceLow = Color(0xFFF4F3F1);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFE9E8E5);
  static const surfaceHighest = Color(0xFFDDDDD9);
  static const surfaceDim = Color(0xFFEDE8E0);
  static const primary = Color(0xFF004D49);
  static const primarySoft = Color(0xFF196661);
  static const primaryContainer = Color(0xFFCCE8E4);
  static const secondaryContainer = Color(0xFFE3E2E0);
  static const onSecondaryContainer = Color(0xFF3F4947);
  static const onSurface = Color(0xFF1A1C1A);
  static const onSurfaceVar = Color(0xFF4A5552);
  static const onSurfaceMut = Color(0xFF8A938F);
  static const gold = Color(0xFFE9B949);
  static const goldSoft = Color(0xFFF4DFA6);
  static const bronze = Color(0xFF9A7E4E);
  static const goldDeep = Color(0xFF8A6B1A);
  static const error = Color(0xFFBA1A1A);
  static const errorSoft = Color(0xFFFFDAD6);
  static const success = Color(0xFF196661);
  static const outline = Color(0x4DBEC9C7);
}

@immutable
class CrudoColors extends ThemeExtension<CrudoColors> {
  const CrudoColors({
    required this.surface,
    required this.surfaceLow,
    required this.surfaceLowest,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.surfaceDim,
    required this.primary,
    required this.primarySoft,
    required this.primaryContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.onSurface,
    required this.onSurfaceVar,
    required this.onSurfaceMut,
    required this.gold,
    required this.goldSoft,
    required this.bronze,
    required this.goldDeep,
    required this.error,
    required this.errorSoft,
    required this.success,
    required this.outline,
  });

  final Color surface,
      surfaceLow,
      surfaceLowest,
      surfaceHigh,
      surfaceHighest,
      surfaceDim;
  final Color primary, primarySoft, primaryContainer;
  final Color secondaryContainer, onSecondaryContainer;
  final Color onSurface, onSurfaceVar, onSurfaceMut;
  final Color gold,
      goldSoft,
      bronze,
      goldDeep,
      error,
      errorSoft,
      success,
      outline;

  static const light = CrudoColors(
    surface: CrudoPalette.surface,
    surfaceLow: CrudoPalette.surfaceLow,
    surfaceLowest: CrudoPalette.surfaceLowest,
    surfaceHigh: CrudoPalette.surfaceHigh,
    surfaceHighest: CrudoPalette.surfaceHighest,
    surfaceDim: CrudoPalette.surfaceDim,
    primary: CrudoPalette.primary,
    primarySoft: CrudoPalette.primarySoft,
    primaryContainer: CrudoPalette.primaryContainer,
    secondaryContainer: CrudoPalette.secondaryContainer,
    onSecondaryContainer: CrudoPalette.onSecondaryContainer,
    onSurface: CrudoPalette.onSurface,
    onSurfaceVar: CrudoPalette.onSurfaceVar,
    onSurfaceMut: CrudoPalette.onSurfaceMut,
    gold: CrudoPalette.gold,
    goldSoft: CrudoPalette.goldSoft,
    bronze: CrudoPalette.bronze,
    goldDeep: CrudoPalette.goldDeep,
    error: CrudoPalette.error,
    errorSoft: CrudoPalette.errorSoft,
    success: CrudoPalette.success,
    outline: CrudoPalette.outline,
  );

  @override
  CrudoColors copyWith({
    Color? surface,
    Color? surfaceLow,
    Color? surfaceLowest,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? surfaceDim,
    Color? primary,
    Color? primarySoft,
    Color? primaryContainer,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? onSurface,
    Color? onSurfaceVar,
    Color? onSurfaceMut,
    Color? gold,
    Color? goldSoft,
    Color? bronze,
    Color? goldDeep,
    Color? error,
    Color? errorSoft,
    Color? success,
    Color? outline,
  }) {
    return CrudoColors(
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceLowest: surfaceLowest ?? this.surfaceLowest,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVar: onSurfaceVar ?? this.onSurfaceVar,
      onSurfaceMut: onSurfaceMut ?? this.onSurfaceMut,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      bronze: bronze ?? this.bronze,
      goldDeep: goldDeep ?? this.goldDeep,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      success: success ?? this.success,
      outline: outline ?? this.outline,
    );
  }

  /// Accent colors for the three macros, shared between food-form fields and
  /// intake-card bars. Protein → primary, Carbs → gold, Fats → bronze.
  Color get proteinColor => primary;
  Color get carbsColor => gold;
  Color get fatsColor => bronze;

  @override
  CrudoColors lerp(ThemeExtension<CrudoColors>? other, double t) {
    if (other is! CrudoColors) return this;
    return CrudoColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceLowest: Color.lerp(surfaceLowest, other.surfaceLowest, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      onSecondaryContainer: Color.lerp(
        onSecondaryContainer,
        other.onSecondaryContainer,
        t,
      )!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVar: Color.lerp(onSurfaceVar, other.onSurfaceVar, t)!,
      onSurfaceMut: Color.lerp(onSurfaceMut, other.onSurfaceMut, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      bronze: Color.lerp(bronze, other.bronze, t)!,
      goldDeep: Color.lerp(goldDeep, other.goldDeep, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}
