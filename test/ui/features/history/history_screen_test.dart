import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/features/history/view_models/history_providers.dart';
import 'package:crudo/ui/features/history/views/history_screen.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime.utc(2026, 6, 10);
  final yesterday = DateTime.utc(2026, 6, 9);
  final twoDaysAgo = DateTime.utc(2026, 6, 8);
  final threeDaysAgo = DateTime.utc(2026, 6, 7);
  final fourDaysAgo = DateTime.utc(2026, 6, 6);

  WeekCell weekCell(
    DateTime date, {
    double adherence = 0.0,
    DayState? state,
    required DayCellKind kind,
  }) {
    return (date: date, adherence: adherence, state: state, kind: kind);
  }

  RecentDay recentDay(
    DateTime date, {
    double adherence = 0.0,
    required DayState state,
    int done = 0,
    int total = 1,
  }) {
    return (
      date: date,
      adherence: adherence,
      state: state,
      done: done,
      total: total,
    );
  }

  Widget testableHistoryScreen() {
    return ProviderScope(
      overrides: [
        streakProvider.overrideWith(
          (ref) => Stream.value(const Streak(current: 12, personalBest: 21)),
        ),
        weeklyAdherenceProvider.overrideWith(
          (ref) => Future.value([
            weekCell(
              DateTime.utc(2026, 6, 8),
              adherence: 0.0,
              state: DayState.red,
              kind: DayCellKind.locked,
            ),
            weekCell(
              DateTime.utc(2026, 6, 9),
              adherence: 1.0,
              state: DayState.green,
              kind: DayCellKind.locked,
            ),
            weekCell(
              DateTime.utc(2026, 6, 10),
              adherence: 1.0,
              state: DayState.green,
              kind: DayCellKind.today,
            ),
            weekCell(DateTime.utc(2026, 6, 11), kind: DayCellKind.future),
            weekCell(DateTime.utc(2026, 6, 12), kind: DayCellKind.future),
            weekCell(DateTime.utc(2026, 6, 13), kind: DayCellKind.future),
            weekCell(DateTime.utc(2026, 6, 14), kind: DayCellKind.future),
          ]),
        ),
        historyStatsProvider.overrideWith(
          (ref) => Future.value((
            adherencePct: 87,
            mealsDone: 142,
            avgKcal: 2180,
            skipped: 7,
          )),
        ),
        recentDaysProvider.overrideWith(
          (ref) => Future.value([
            recentDay(
              today,
              adherence: 1.0,
              state: DayState.green,
              done: 4,
              total: 4,
            ),
            recentDay(
              yesterday,
              adherence: 1.0,
              state: DayState.green,
              done: 4,
              total: 4,
            ),
            recentDay(
              twoDaysAgo,
              adherence: 0.0,
              state: DayState.red,
              done: 0,
              total: 4,
            ),
            recentDay(
              threeDaysAgo,
              adherence: 1.0,
              state: DayState.green,
              done: 3,
              total: 3,
            ),
            recentDay(
              fourDaysAgo,
              adherence: 0.8,
              state: DayState.yellow,
              done: 3,
              total: 4,
            ),
          ]),
        ),
        clockProvider.overrideWithValue(() => DateTime(2026, 6, 10, 10, 0)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[CrudoColors.light],
        ),
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
  }

  group('HistoryScreen', () {
    testWidgets('renders streak hero, stat grid, and recent list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testableHistoryScreen());
      await tester.pumpAndSettle();

      // Streak hero
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Personal best: 21'), findsOneWidget);

      // Stat grid
      expect(find.text('87%'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('2180'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      // Week strip with 7 bars
      expect(find.byKey(const ValueKey('week-strip')), findsOneWidget);
      expect(find.byKey(const ValueKey('week-bar')), findsNWidgets(7));

      // 5 recent rows
      expect(find.byKey(const ValueKey('recent-day-row')), findsNWidgets(5));

      // Calendar button
      expect(
        find.byKey(const ValueKey('history-calendar-btn')),
        findsOneWidget,
      );
    });
  });
}
