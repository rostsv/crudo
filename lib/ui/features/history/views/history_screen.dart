import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/typography.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/toast.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          const Text('History', style: CrudoText.headline),
          const SizedBox(height: Spacing.lg),
          const _DemoCounter(),
          const SizedBox(height: Spacing.lg),
          Center(
            child: GestureDetector(
              onTap: () => showCrudoToast(context, 'Looking good!'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: CrudoColors.light.surfaceHigh,
                  borderRadius: Radii.all(Radii.full),
                ),
                child: Text(
                  'Trigger toast',
                  style: CrudoText.labelMd.copyWith(
                    color: CrudoColors.light.onSurfaceVar,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCounter extends StatefulWidget {
  const _DemoCounter();

  @override
  State<_DemoCounter> createState() => _DemoCounterState();
}

class _DemoCounterState extends State<_DemoCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('demo-counter'),
      onTap: () => setState(() => _count++),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: CrudoColors.light.surfaceLowest,
          borderRadius: Radii.all(Radii.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Taps: $_count', style: CrudoText.title)],
        ),
      ),
    );
  }
}
