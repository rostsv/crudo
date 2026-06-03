import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('selection switches fill, never adds a border', (tester) async {
    for (final selected in [true, false]) {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          SelectionCard(
            title: 'Cut plan',
            subtitle: '5 meals',
            selected: selected,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final deco =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      check(deco.border).isNull();
      check(deco.color).equals(
        selected
            ? CrudoColors.light.primaryContainer
            : CrudoColors.light.surfaceLowest,
      );
      await tester.tap(find.text('Cut plan'));
      check(taps).equals(1);
    }
  });
}
