import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  test('CrudoColors.light exposes exact tokens', () {
    const c = CrudoColors.light;
    expect(c.gold, const Color(0xFFE9B949));
    expect(c.goldDeep, const Color(0xFF8A6B1A));
    expect(c.surface, const Color(0xFFFAF9F6));
    expect(c.onSurfaceMut, const Color(0xFF8A938F));
    expect(c.secondaryContainer, const Color(0xFFE3E2E0));
    expect(c.onSecondaryContainer, const Color(0xFF3F4947));
  });

  test('lerp returns a CrudoColors', () {
    final r = CrudoColors.light.lerp(CrudoColors.light, 0.5);
    expect(r, isA<CrudoColors>());
  });
}
