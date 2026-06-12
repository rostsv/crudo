import 'package:checks/checks.dart';
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_notification_service.dart';

void main() {
  group('FakeNotificationService', () {
    late FakeNotificationService fake;

    setUp(() {
      fake = FakeNotificationService();
    });

    tearDown(() {
      fake.dispose();
    });

    test('scheduleAll records specs and bumps cancelAllCount', () async {
      final spec1 = NotificationSpec(
        id: 1,
        kind: NotificationKind.at,
        fireAt: DateTime.utc(2026, 6, 11, 12, 30),
        title: 'Time to eat',
        body: 'Time to eat Lunch',
        mealId: 'm1',
        withActions: true,
      );
      final spec2 = NotificationSpec(
        id: 2,
        kind: NotificationKind.pre,
        fireAt: DateTime.utc(2026, 6, 11, 11, 45),
        title: 'Coming up',
        body: 'Lunch in 45 min',
        mealId: 'm1',
      );

      check(fake.cancelAllCount).equals(0);
      check(fake.scheduled).isEmpty();

      await fake.scheduleAll([spec1, spec2]);

      check(fake.cancelAllCount).equals(1);
      check(fake.scheduled).length.equals(1);
      check(fake.scheduled[0]).length.equals(2);
      check(fake.scheduled[0][0].id).equals(1);
      check(fake.scheduled[0][1].id).equals(2);
    });

    test('emitAction is received on actions stream', () async {
      final received = <NotificationAction>[];
      final sub = fake.actions.listen(received.add);

      final action = (mealId: 'm1', kind: NotificationActionKind.ateIt);
      fake.emitAction(action);

      // Yield to let the stream deliver.
      await Future<void>.delayed(Duration.zero);

      check(received).length.equals(1);
      check(received[0].mealId).equals('m1');
      check(received[0].kind).equals(NotificationActionKind.ateIt);

      await sub.cancel();
    });

    test('consumeLaunchAction returns preset once then null', () async {
      fake.launchAction = (mealId: 'm2', kind: NotificationActionKind.skip);

      final first = await fake.consumeLaunchAction();
      check(first).isNotNull();
      check(first!.mealId).equals('m2');
      check(first.kind).equals(NotificationActionKind.skip);

      final second = await fake.consumeLaunchAction();
      check(second).isNull();
    });
  });
}
