import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'ui/core/themes/theme.dart';

/// Root application widget — boots straight into the 4-tab shell.
class CrudoApp extends ConsumerWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
