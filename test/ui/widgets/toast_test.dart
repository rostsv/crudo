import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({String? body, ToastKind kind = ToastKind.success}) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            showCrudoToast(context, 'Plan saved', body: body, kind: kind),
        child: const Text('go'),
      ),
    ),
  ),
);

void main() {
  testWidgets('toast shows title + body then auto-dismisses', (tester) async {
    await tester.pumpWidget(_host(body: 'Mon–Fri, 4 meals.'));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Plan saved'), findsOneWidget);
    expect(find.text('Mon–Fri, 4 meals.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4600));
    expect(find.text('Plan saved'), findsNothing);
  });

  testWidgets('dismiss button removes the toast early', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Plan saved'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toast-dismiss')));
    await tester.pump();
    expect(find.text('Plan saved'), findsNothing);
  });

  testWidgets('every kind renders', (tester) async {
    for (final kind in ToastKind.values) {
      await tester.pumpWidget(_host(kind: kind));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('Plan saved'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 4600));
      expect(find.text('Plan saved'), findsNothing);
    }
  });
}
