import 'package:checks/checks.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationId', () {
    test('deterministic: same inputs → same id', () {
      check(
        notificationId('m1', NotificationKind.at),
      ).equals(notificationId('m1', NotificationKind.at));
    });

    test('kind-distinct: different kind → different id', () {
      check(
        notificationId('m1', NotificationKind.at),
      ).not((i) => i.equals(notificationId('m1', NotificationKind.pre)));
    });

    test('non-negative: result is >= 0', () {
      check(notificationId('m1', NotificationKind.at)).isGreaterOrEqual(0);
    });

    test('mealId null also works deterministically', () {
      check(
        notificationId(null, NotificationKind.endOfDay),
      ).equals(notificationId(null, NotificationKind.endOfDay));
    });
  });

  group('NotificationSpec', () {
    test('non-UTC fireAt throws AssertionError', () {
      check(
        () => NotificationSpec(
          id: 1,
          kind: NotificationKind.at,
          fireAt: DateTime(2026),
          title: 't',
          body: 'b',
        ),
      ).throws();
    });

    test('UTC fireAt constructs successfully', () {
      final spec = NotificationSpec(
        id: 1,
        kind: NotificationKind.at,
        fireAt: DateTime.utc(2026, 6, 11, 12, 30),
        title: 'Time to eat',
        body: 'Time to eat Lunch',
        mealId: 'm1',
        withActions: true,
      );
      check(spec.id).equals(1);
      check(spec.kind).equals(NotificationKind.at);
      check(spec.fireAt.isUtc).isTrue();
      check(spec.title).equals('Time to eat');
      check(spec.body).equals('Time to eat Lunch');
      check(spec.mealId).equals('m1');
      check(spec.withActions).isTrue();
    });

    test('default withActions is false', () {
      final spec = NotificationSpec(
        id: 2,
        kind: NotificationKind.pre,
        fireAt: DateTime.utc(2026, 6, 11, 12, 0),
        title: 'Coming up',
        body: 'Lunch in 30 min',
        mealId: 'm1',
      );
      check(spec.withActions).isFalse();
    });

    test('mealId can be null for endOfDay/risk', () {
      final spec = NotificationSpec(
        id: 3,
        kind: NotificationKind.endOfDay,
        fireAt: DateTime.utc(2026, 6, 11, 21, 30),
        title: 'Daily recap',
        body: '1500 of 2000 kcal',
      );
      check(spec.mealId).isNull();
    });
  });
}
