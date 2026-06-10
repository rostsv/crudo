import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/history/view_models/history_providers.dart';
import 'package:crudo/ui/features/history/views/calendar_sheet.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final month = DateTime.utc(2026, 6, 1);

  CalendarCell? gridCell(
    DateTime date, {
    DayState? state,
    required DayCellKind kind,
    int done = 0,
    int total = 0,
    int kcal = 0,
    int adherencePct = 0,
  }) {
    return (
      date: date,
      state: state,
      kind: kind,
      done: done,
      total: total,
      kcal: kcal,
      adherencePct: adherencePct,
    );
  }

  List<CalendarCell?> buildGrid() {
    final result = <CalendarCell?>[];
    // June 1-7 (week 1)
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 1),
        state: DayState.green,
        kind: DayCellKind.locked,
        done: 2,
        total: 2,
        kcal: 500,
        adherencePct: 100,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 2),
        state: DayState.yellow,
        kind: DayCellKind.locked,
        done: 1,
        total: 2,
        kcal: 300,
        adherencePct: 60,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 3),
        state: DayState.red,
        kind: DayCellKind.locked,
        done: 0,
        total: 2,
        kcal: 0,
        adherencePct: 0,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 4),
        state: DayState.green,
        kind: DayCellKind.locked,
        done: 3,
        total: 3,
        kcal: 800,
        adherencePct: 100,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 5),
        state: DayState.green,
        kind: DayCellKind.locked,
        done: 2,
        total: 2,
        kcal: 500,
        adherencePct: 100,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 6),
        state: DayState.yellow,
        kind: DayCellKind.locked,
        done: 1,
        total: 2,
        kcal: 300,
        adherencePct: 60,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 7),
        state: DayState.red,
        kind: DayCellKind.locked,
        done: 0,
        total: 2,
        kcal: 0,
        adherencePct: 0,
      ),
    );
    // June 8-14 (week 2)
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 8),
        state: DayState.green,
        kind: DayCellKind.locked,
        done: 2,
        total: 2,
        kcal: 500,
        adherencePct: 100,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 9),
        state: DayState.green,
        kind: DayCellKind.locked,
        done: 2,
        total: 2,
        kcal: 500,
        adherencePct: 100,
      ),
    );
    result.add(
      gridCell(
        DateTime.utc(2026, 6, 10),
        state: DayState.green,
        kind: DayCellKind.today,
        done: 2,
        total: 2,
        kcal: 500,
        adherencePct: 100,
      ),
    );
    // June 11-30 (future)
    for (var i = 11; i <= 30; i++) {
      result.add(
        gridCell(
          DateTime.utc(2026, 6, i),
          state: null,
          kind: DayCellKind.future,
          done: 0,
          total: 0,
          kcal: 0,
          adherencePct: 0,
        ),
      );
    }
    // July 1-5 (trailing nulls)
    for (var i = 0; i < 5; i++) {
      result.add(null);
    }
    return result;
  }

  Widget testableCalendar() {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 6, 10, 10, 0)),
        monthGridProvider(
          month,
        ).overrideWith((ref) => Future.value(buildGrid())),
      ],
      child: MaterialApp(
        theme: crudoTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCalendarSheet(context),
            child: const Text('Open calendar'),
          ),
        ),
      ),
    );
  }

  group('CalendarSheet', () {
    testWidgets('renders month title, weekday headers, and summary counts', (
      tester,
    ) async {
      await tester.pumpWidget(testableCalendar());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open calendar'));
      await tester.pumpAndSettle();

      // Month title
      expect(find.text('June 2026'), findsOneWidget);

      // Weekday headers
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2)); // Tuesday and Thursday
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsNWidgets(2)); // Saturday and Sunday

      // KEPT = 6 green, PARTIAL = 2 yellow, MISSED = 2 red
      // Verify via keyed summary badge counts
      expect(find.byKey(const ValueKey('summary-KEPT')), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-PARTIAL')), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-MISSED')), findsOneWidget);
      check(
        tester.widget<Text>(find.byKey(const ValueKey('summary-KEPT'))).data,
      ).equals('6');
      check(
        tester.widget<Text>(find.byKey(const ValueKey('summary-PARTIAL'))).data,
      ).equals('2');
      check(
        tester.widget<Text>(find.byKey(const ValueKey('summary-MISSED'))).data,
      ).equals('2');
    });

    testWidgets('tapping a green cell shows its detail', (tester) async {
      await tester.pumpWidget(testableCalendar());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open calendar'));
      await tester.pumpAndSettle();

      // The sheet opens with today (June 10) selected by default.
      // Tap June 1 (green cell) to change the selection.
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Detail should show 2/2 meals, 500 kcal, and 100%
      expect(find.text('2/2 meals'), findsOneWidget);
      expect(find.text('500 kcal'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
