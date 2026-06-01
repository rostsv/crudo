import 'package:flutter/material.dart';
import 'colors.dart';

abstract final class CrudoText {
  static const _f = 'Manrope';

  static const display = TextStyle(
    fontFamily: _f,
    fontSize: 40,
    height: 1.10,
    letterSpacing: -1.2,
    fontWeight: FontWeight.w600,
    color: CrudoPalette.onSurface,
  );
  static const displaySm = TextStyle(
    fontFamily: _f,
    fontSize: 32,
    height: 1.125,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w600,
    color: CrudoPalette.onSurface,
  );
  static const headline = TextStyle(
    fontFamily: _f,
    fontSize: 24,
    height: 1.25,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
    color: CrudoPalette.onSurface,
  );
  static const headlineSm = TextStyle(
    fontFamily: _f,
    fontSize: 20,
    height: 1.40,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w700,
    color: CrudoPalette.onSurface,
  );
  static const title = TextStyle(
    fontFamily: _f,
    fontSize: 18,
    height: 1.55,
    fontWeight: FontWeight.w600,
    color: CrudoPalette.onSurface,
  );
  static const body = TextStyle(
    fontFamily: _f,
    fontSize: 14,
    height: 1.57,
    fontWeight: FontWeight.w500,
    color: CrudoPalette.onSurfaceVar,
  );
  static const bodyLg = TextStyle(
    fontFamily: _f,
    fontSize: 16,
    height: 1.63,
    fontWeight: FontWeight.w500,
    color: CrudoPalette.onSurfaceVar,
  );
  static const label = TextStyle(
    fontFamily: _f,
    fontSize: 10,
    height: 1.40,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w700,
    color: CrudoPalette.onSurfaceMut,
  );
  static const labelMd = TextStyle(
    fontFamily: _f,
    fontSize: 12,
    height: 1.40,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w700,
    color: CrudoPalette.onSurfaceMut,
  );

  static const textTheme = TextTheme(
    displayLarge: display,
    displayMedium: displaySm,
    headlineMedium: headline,
    headlineSmall: headlineSm,
    titleLarge: title,
    bodyMedium: body,
    bodyLarge: bodyLg,
    labelSmall: label,
    labelMedium: labelMd,
  );
}
