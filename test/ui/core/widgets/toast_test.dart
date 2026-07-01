import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ToastLauncher extends StatelessWidget {
  final ToastKind kind;
  const _ToastLauncher({required this.kind});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: crudoTheme,
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showCrudoToast(
                  context,
                  'Test title',
                  body: 'Test body',
                  kind: kind,
                ),
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  group('kind mapping', () {
    for (final kind in ToastKind.values) {
      testWidgets('${kind.name} uses correct accent, tint, and badge icon', (
        tester,
      ) async {
        await tester.pumpWidget(_ToastLauncher(kind: kind));
        await tester.tap(find.text('Show'));
        await tester.pump();

        final (expectedAccent, expectedTint, expectedIcon) = switch (kind) {
          ToastKind.success => (
            CrudoColors.light.success,
            CrudoColors.light.primaryContainer,
            Icons.check,
          ),
          ToastKind.warn => (
            CrudoColors.light.gold,
            CrudoColors.light.goldSoft,
            Icons.priority_high,
          ),
          ToastKind.error => (
            CrudoColors.light.error,
            CrudoColors.light.errorSoft,
            Icons.close,
          ),
        };

        final badgeContainerFinder = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        );
        final iconFinder = find.descendant(
          of: badgeContainerFinder,
          matching: find.byType(Icon),
        );
        expect(iconFinder, findsOneWidget);
        final icon = tester.widget<Icon>(iconFinder);
        check(icon.icon).equals(expectedIcon);
        check(icon.color).equals(CrudoColors.light.surfaceLowest);

        final badgeContainer = tester.widget<Container>(badgeContainerFinder);
        check(
          (badgeContainer.decoration as BoxDecoration).color,
        ).equals(expectedAccent);

        final cardContainer = tester
            .widgetList<Container>(find.byType(Container))
            .firstWhere(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).boxShadow != null &&
                  (c.decoration as BoxDecoration).color == expectedTint,
            );
        check(
          (cardContainer.decoration as BoxDecoration).color,
        ).equals(expectedTint);

        // The borderless card must not use a Border / BoxBorder.
        final allDecorations = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) => c.decoration is BoxDecoration)
            .map((c) => (c.decoration as BoxDecoration));
        check(allDecorations.every((d) => d.border == null)).isTrue();

        // Dismiss to cancel the auto-dismiss timer before the test ends.
        await tester.tap(find.byKey(const ValueKey('toast-dismiss')));
        await tester.pump();
      });
    }
  });

  testWidgets('toast is anchored near the top', (tester) async {
    await tester.pumpWidget(const _ToastLauncher(kind: ToastKind.success));
    await tester.tap(find.text('Show'));
    await tester.pump();

    final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
    final toastRect = tester.getRect(find.text('Test title'));
    check(toastRect.top).isLessThan(screenHeight / 2);

    await tester.tap(find.byKey(const ValueKey('toast-dismiss')));
    await tester.pump();
  });

  testWidgets('title is bold and body is muted', (tester) async {
    await tester.pumpWidget(const _ToastLauncher(kind: ToastKind.success));
    await tester.tap(find.text('Show'));
    await tester.pump();

    final title = tester.widget<Text>(find.text('Test title'));
    check(title.style!.fontWeight).equals(FontWeight.w700);
    check(title.style!.color).equals(CrudoColors.light.onSurface);

    final body = tester.widget<Text>(find.text('Test body'));
    check(body.style!.color).equals(CrudoColors.light.onSurfaceMut);

    await tester.tap(find.byKey(const ValueKey('toast-dismiss')));
    await tester.pump();
  });

  testWidgets('dismiss X removes the toast', (tester) async {
    await tester.pumpWidget(const _ToastLauncher(kind: ToastKind.success));
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.text('Test title'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toast-dismiss')));
    await tester.pump();
    expect(find.text('Test title'), findsNothing);
  });
}
