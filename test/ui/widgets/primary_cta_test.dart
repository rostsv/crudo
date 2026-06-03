import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('fires onPressed when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PrimaryCta(label: 'Save', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Save'));
    check(taps).equals(1);
  });

  testWidgets('blocks taps when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PrimaryCta(label: 'Save', enabled: false, onPressed: () => taps++)),
    );
    await tester.tap(find.text('Save'));
    check(taps).equals(0);
  });

  testWidgets('uses gradient, no BoxShadow', (tester) async {
    await tester.pumpWidget(_wrap(PrimaryCta(label: 'Save', onPressed: () {})));
    final deco =
        tester
                .widget<Container>(
                  find.byKey(const ValueKey('primary-cta-surface')),
                )
                .decoration!
            as BoxDecoration;
    check(deco.gradient).isNotNull();
    check(deco.boxShadow).isNull();
  });
}
