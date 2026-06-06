import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mutable fake clock: local 2026-06-04 09:30.
  var now = DateTime(2026, 6, 4, 9, 30);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('todayProvider emits the UTC day-label of the local clock', () {
    final c = container();
    check(c.read(todayProvider)).equals(DateTime.utc(2026, 6, 4));
  });

  test('refresh() rolls today over when the clock crosses midnight', () {
    final c = container();
    check(c.read(todayProvider)).equals(DateTime.utc(2026, 6, 4));
    now = DateTime(2026, 6, 5, 0, 0, 30);
    c.read(todayProvider.notifier).refresh();
    check(c.read(todayProvider)).equals(DateTime.utc(2026, 6, 5));
  });

  test(
    'selectedDate defaults to today, selects, and snaps back on rollover',
    () {
      now = DateTime(2026, 6, 4, 9, 30);
      final c = container();
      check(c.read(selectedDateProvider)).equals(DateTime.utc(2026, 6, 4));

      c.read(selectedDateProvider.notifier).select(DateTime.utc(2026, 6, 6));
      check(c.read(selectedDateProvider)).equals(DateTime.utc(2026, 6, 6));

      now = DateTime(2026, 6, 5, 8, 0);
      c.read(todayProvider.notifier).refresh();
      check(c.read(selectedDateProvider)).equals(DateTime.utc(2026, 6, 5));
    },
  );

  testWidgets('streakCount maps the repository stream', (tester) async {
    final c = container();

    // Keep the provider alive with a widget that watches it.
    await tester.pumpWidget(
      MaterialApp(
        home: UncontrolledProviderScope(
          container: c,
          child: Consumer(
            builder: (context, ref, child) {
              final asyncValue = ref.watch(streakCountProvider);
              return asyncValue.when(
                data: (v) => Text('$v'),
                loading: () => const Text('loading'),
                error: (e, s) => const Text('error'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);

    // Update repo; the provider must reflect the change.
    await c
        .read(streakRepositoryProvider)
        .save(const Streak(current: 7, personalBest: 9));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
  });
}
