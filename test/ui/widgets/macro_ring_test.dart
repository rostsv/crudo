import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/macro_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('paints and shows the center overlay', (tester) async {
    await tester.pumpWidget(
      _wrap(const MacroRing(value: 0.62, center: Text('2 040'))),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('2 040'), findsOneWidget);
  });

  testWidgets('zero value still renders (track only)', (tester) async {
    await tester.pumpWidget(_wrap(const MacroRing(value: 0)));
    expect(find.byType(MacroRing), findsOneWidget);
  });

  testWidgets('out-of-range values render without error', (tester) async {
    await tester.pumpWidget(_wrap(const MacroRing(value: 1.7)));
    expect(find.byType(MacroRing), findsOneWidget);
    await tester.pumpWidget(_wrap(const MacroRing(value: -0.3)));
    expect(find.byType(MacroRing), findsOneWidget);
  });
}
