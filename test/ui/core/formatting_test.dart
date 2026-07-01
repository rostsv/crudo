import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foodCategoryIcon maps every FoodCategory to a non-null icon', () {
    final icons = {for (final c in FoodCategory.values) c: foodCategoryIcon(c)};
    for (final icon in icons.values) {
      check(icon).isA<IconData>();
    }
  });
}
