import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  test('crudoTheme wiring', () {
    final t = crudoTheme;
    expect(t.useMaterial3, true);
    expect(t.colorScheme.primary, const Color(0xFF004D49));
    expect(t.colorScheme.surface, const Color(0xFFFAF9F6));
    expect(t.extension<CrudoColors>()!.gold, const Color(0xFFE9B949));
    expect(t.textTheme.titleLarge?.fontSize, 18);
  });
}
