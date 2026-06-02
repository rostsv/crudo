import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'ui/core/themes/theme.dart';
import 'ui/core/themes/typography.dart';

/// Root application widget. No router yet — that lands in S04.
class CrudoApp extends ConsumerWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      home: const _BootPlaceholder(),
    );
  }
}

class _BootPlaceholder extends ConsumerWidget {
  const _BootPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDev = ref.watch(appConfigProvider).isDev;
    return Scaffold(
      body: Stack(
        children: [
          Center(child: Text('Crudo', style: CrudoText.display)),
          if (isDev)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: Text('Crudo Dev', style: CrudoText.label),
            ),
        ],
      ),
    );
  }
}
