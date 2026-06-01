import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

final ThemeData crudoTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Manrope',
  scaffoldBackgroundColor: CrudoPalette.surface,
  textTheme: CrudoText.textTheme,
  extensions: const [CrudoColors.light],
  colorScheme: const ColorScheme.light(
    primary: CrudoPalette.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: CrudoPalette.primaryContainer,
    onPrimaryContainer: CrudoPalette.primary,
    surface: CrudoPalette.surface,
    surfaceContainerLow: CrudoPalette.surfaceLow,
    surfaceContainerLowest: CrudoPalette.surfaceLowest,
    surfaceContainerHigh: CrudoPalette.surfaceHigh,
    surfaceContainerHighest: CrudoPalette.surfaceHighest,
    onSurface: CrudoPalette.onSurface,
    onSurfaceVariant: CrudoPalette.onSurfaceVar,
    outlineVariant: Color(0xFFBEC9C7),
    error: CrudoPalette.error,
    errorContainer: CrudoPalette.errorSoft,
  ),
);
