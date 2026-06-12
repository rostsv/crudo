import 'package:checks/checks.dart';
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/data/services/flutter_local_notifications_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('implements NotificationService', () {
    // Construction smoke — proves the class satisfies the port.
    // Do NOT call init/scheduleAll (no platform binding).
    final svc = FlutterLocalNotificationsNotificationService();
    check(svc).isA<NotificationService>();
  });
}
