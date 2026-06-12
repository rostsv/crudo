import 'dart:async';

import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_spec.dart';

/// Records scheduleAll/cancelAll calls; lets tests push synthetic actions and
/// preload a launch action. No real plugin.
class FakeNotificationService implements NotificationService {
  final List<List<NotificationSpec>> scheduled = [];
  int cancelAllCount = 0;
  bool permissionGranted = true;
  NotificationAction? launchAction;
  final _actions = StreamController<NotificationAction>.broadcast();

  void emitAction(NotificationAction a) => _actions.add(a);

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> cancelAll() async => cancelAllCount++;

  @override
  Future<void> scheduleAll(List<NotificationSpec> specs) async {
    cancelAllCount++;
    scheduled.add(specs);
  }

  @override
  Stream<NotificationAction> get actions => _actions.stream;

  @override
  Future<NotificationAction?> consumeLaunchAction() async {
    final a = launchAction;
    launchAction = null;
    return a;
  }

  void dispose() => _actions.close();
}
