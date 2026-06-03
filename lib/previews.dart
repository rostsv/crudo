import 'package:flutter/material.dart';

import 'domain/shared/enums.dart';
import 'ui/core/themes/colors.dart';
import 'ui/core/themes/theme.dart';
import 'ui/core/themes/dimensions.dart';
import 'ui/core/themes/typography.dart';
import 'ui/core/widgets/primary_cta.dart';
import 'ui/core/widgets/pill.dart';
import 'ui/core/widgets/selection_card.dart';
import 'ui/core/widgets/meal_card.dart';
import 'ui/core/widgets/macro_ring.dart';
import 'ui/core/widgets/sheet.dart';
import 'ui/core/widgets/toast.dart';

/// Widget preview showcase — renders every core widget in all relevant states.
/// Run as a standalone app for visual review; not wired into production routing.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crudo Widget Previews',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrudoColors.light.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            const Text('PrimaryCta', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            PrimaryCta(label: 'Enabled', onPressed: () {}),
            const SizedBox(height: Spacing.sm),
            const PrimaryCta(
              label: 'Disabled',
              onPressed: null,
              enabled: false,
            ),
            const SizedBox(height: Spacing.lg),

            const Text('Pill', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                Pill(label: 'Selected', selected: true, onTap: () {}),
                Pill(label: 'Unselected', selected: false, onTap: () {}),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            const Text('SelectionCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            SelectionCard(
              title: 'Selected',
              subtitle: 'Subtitle',
              selected: true,
              onTap: () {},
            ),
            const SizedBox(height: Spacing.sm),
            SelectionCard(
              title: 'Unselected',
              subtitle: 'Subtitle',
              selected: false,
              onTap: () {},
            ),
            const SizedBox(height: Spacing.lg),

            const Text('MealCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            for (final status in MealStatus.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: MealCard(
                  title: 'Meal — ${status.name}',
                  timeLabel: '08:00',
                  kcalLabel: '420 kcal',
                  status: status,
                ),
              ),
            const SizedBox(height: Spacing.lg),

            const Text('MacroRing', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            const Center(
              child: MacroRing(
                protein: 120,
                carbs: 200,
                fats: 60,
                centerLabel: '2 040',
              ),
            ),
            const SizedBox(height: Spacing.lg),

            const Text('SheetScaffold', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            PrimaryCta(
              label: 'Open sheet',
              onPressed: () => showCrudoSheet<void>(
                context,
                builder: (_) => const SheetScaffold(
                  title: 'Demo',
                  body: Center(child: Text('Sheet content')),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            const Text('Toast', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            PrimaryCta(
              label: 'Show toast',
              onPressed: () => showCrudoToast(context, 'Preview toast!'),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}
