import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'config/di.dart';
import 'data/services/seed_service.dart';

/// Shared entry path for every flavor: build config, load the bundled seed,
/// scope everything, run the app.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final seedFoods = await SeedService().loadFoods();
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        seedFoodsProvider.overrideWithValue(seedFoods),
      ],
      child: const CrudoApp(),
    ),
  );
}
