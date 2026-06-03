import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toast shows then auto-dismisses', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: crudoTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCrudoToast(context, 'Plan saved'),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Plan saved'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2600));
    expect(find.text('Plan saved'), findsNothing);
  });
}
