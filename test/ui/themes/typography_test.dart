import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/typography.dart';

void main() {
  test('display style', () {
    expect(CrudoText.display.fontSize, 40);
    expect(CrudoText.display.fontWeight, FontWeight.w600);
    expect(CrudoText.display.letterSpacing, -1.2);
    expect(CrudoText.display.fontFamily, 'Manrope');
  });
  test('label tracked + textTheme wired', () {
    expect(CrudoText.label.letterSpacing, 1.5);
    expect(CrudoText.textTheme.titleLarge?.fontSize, 18);
  });
}
