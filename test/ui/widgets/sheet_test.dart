import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/core/widgets/sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showCrudoSheet opens a SheetScaffold and closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: crudoTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCrudoSheet<void>(
                context,
                builder: (_) => SheetScaffold(
                  title: 'Snooze',
                  body: const Text('Pick a delay'),
                  cta: PrimaryCta(label: 'Confirm', onPressed: () {}),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Snooze'), findsOneWidget);
    expect(find.text('Pick a delay'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10)); // barrier dismiss
    await tester.pumpAndSettle();
    expect(find.text('Snooze'), findsNothing);
  });
}
