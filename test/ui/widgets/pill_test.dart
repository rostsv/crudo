import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('selected pill fills teal; unselected surface', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Row(
          children: [
            Pill(label: 'Mon', selected: true, onTap: () {}),
            Pill(label: 'Tue', selected: false, onTap: () {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boxes = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    final selected = boxes.first.decoration! as BoxDecoration;
    final unselected = boxes.last.decoration! as BoxDecoration;
    check(selected.color).equals(CrudoColors.light.primary);
    check(unselected.color).equals(CrudoColors.light.surfaceHigh);
  });

  testWidgets('tap fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(Pill(label: 'Mon', selected: false, onTap: () => taps++)),
    );
    await tester.tap(find.text('Mon'));
    check(taps).equals(1);
  });
}
