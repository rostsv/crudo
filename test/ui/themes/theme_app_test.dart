import 'package:crudo/app.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app uses crudoTheme + exposes CrudoColors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(flavor: Flavor.prod),
          ),
        ],
        child: const CrudoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final ctx = tester.element(find.text('Today').first);
    final theme = Theme.of(ctx);
    expect(theme.colorScheme.primary, const Color(0xFF004D49));
    expect(theme.extension<CrudoColors>()!.gold, const Color(0xFFE9B949));
  });
}
