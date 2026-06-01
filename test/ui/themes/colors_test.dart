import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  test('CrudoColors.light exposes exact tokens', () {
    const c = CrudoColors.light;
    expect(c.gold, const Color(0xFFE9B949));
    expect(c.surface, const Color(0xFFFAF9F6));
    expect(c.onSurfaceMut, const Color(0xFF8A938F));
  });

  test('lerp returns a CrudoColors', () {
    final r = CrudoColors.light.lerp(CrudoColors.light, 0.5);
    expect(r, isA<CrudoColors>());
  });
}
