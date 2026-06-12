import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'config/di.dart';
import 'data/services/flutter_local_notifications_notification_service.dart';
import 'data/services/seed_service.dart';

/// Shared entry path for every flavor: build config, load the bundled seed,
/// init the notification service, scope everything, run the app.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final seedFoods = await SeedService().loadFoods();

  // Real notification adapter — initialized + permission-requested before the
  // app reads notificationServiceProvider (which otherwise throws). The
  // scheduler/router activate from AppShell as soon as the shell mounts.
  final notifications = FlutterLocalNotificationsNotificationService();
  await notifications.init();
  await notifications.requestPermission();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        seedFoodsProvider.overrideWithValue(seedFoods),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const CrudoApp(),
    ),
  );
}
