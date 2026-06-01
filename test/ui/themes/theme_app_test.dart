import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/main.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  testWidgets('app uses crudoTheme + exposes CrudoColors', (tester) async {
    await tester.pumpWidget(const CrudoApp());
    final ctx = tester.element(find.text('Crudo'));
    final theme = Theme.of(ctx);
    expect(theme.colorScheme.primary, const Color(0xFF004D49));
    expect(theme.extension<CrudoColors>()!.gold, const Color(0xFFE9B949));
    expect(
      DefaultTextStyle.of(ctx).style.fontFamily ??
          theme.textTheme.bodyMedium?.fontFamily,
      anyOf('Manrope', isNull),
    );
  });
}
