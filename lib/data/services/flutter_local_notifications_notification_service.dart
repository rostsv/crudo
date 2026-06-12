import 'dart:async';

import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Real adapter over FlutterLocalNotificationsPlugin + timezone. Translates
/// each NotificationSpec into a zonedSchedule call; `at` specs attach the three
/// action buttons (Ate it / Snooze / Skip) keyed by mealId payload. No
/// scheduling LOGIC here — the pure schedule decides what/when.
class FlutterLocalNotificationsNotificationService
    implements NotificationService {
  FlutterLocalNotificationsNotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _actionsController = StreamController<NotificationAction>.broadcast();
  bool _initialized = false;

  @override
  Stream<NotificationAction> get actions => _actionsController.stream;

  @override
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // iOS / macOS category with three action buttons
    // Note: DarwinNotificationAction.plain is a non-const factory, so the
    // category and settings cannot be const.
    final darwinCategory = DarwinNotificationCategory(
      'meal',
      actions: [
        DarwinNotificationAction.plain(
          'ate_it',
          'Ate it',
          options: {DarwinNotificationActionOption.foreground},
        ),
        DarwinNotificationAction.plain('snooze', 'Snooze'),
        DarwinNotificationAction.plain('skip', 'Skip'),
      ],
    );

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [darwinCategory],
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final mealId = response.payload;
    final actionId = response.actionId;

    // Ignore plain taps without an action — just opening the app.
    if (mealId == null || actionId == null) return;

    final kind = _parseActionKind(actionId);
    if (kind == null) return;

    _actionsController.add((mealId: mealId, kind: kind));
  }

  NotificationActionKind? _parseActionKind(String actionId) {
    switch (actionId) {
      case 'ate_it':
        return NotificationActionKind.ateIt;
      case 'snooze':
        return NotificationActionKind.snooze;
      case 'skip':
        return NotificationActionKind.skip;
      default:
        return null;
    }
  }

  @override
  Future<bool> requestPermission() async {
    // Android 13+: runtime notification permission
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS: request alert/badge/sound permissions
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // macOS
    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macPlugin != null) {
      final granted = await macPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleAll(List<NotificationSpec> specs) async {
    await cancelAll();

    for (final spec in specs) {
      final scheduledDate = tz.TZDateTime.from(spec.fireAt, tz.UTC);

      final androidActions = spec.withActions
          ? [
              const AndroidNotificationAction(
                'ate_it',
                'Ate it',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction('snooze', 'Snooze'),
              const AndroidNotificationAction('skip', 'Skip'),
            ]
          : null;

      final androidDetails = AndroidNotificationDetails(
        'meal_reminders',
        'Meal reminders',
        channelDescription: 'Reminders for scheduled meals',
        importance: Importance.high,
        priority: Priority.defaultPriority,
        actions: androidActions,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: spec.withActions ? 'meal' : null,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _plugin.zonedSchedule(
        id: spec.id,
        title: spec.title,
        body: spec.body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: spec.mealId,
      );
    }
  }

  @override
  Future<NotificationAction?> consumeLaunchAction() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return null;

    final response = launchDetails!.notificationResponse;
    if (response == null) return null;

    final mealId = response.payload;
    final actionId = response.actionId;

    // Only route action taps (not plain notification opens).
    if (mealId == null || actionId == null) return null;

    final kind = _parseActionKind(actionId);
    if (kind == null) return null;

    return (mealId: mealId, kind: kind);
  }

  /// Close the action stream. Call when disposing the service.
  void dispose() {
    _actionsController.close();
  }
}
