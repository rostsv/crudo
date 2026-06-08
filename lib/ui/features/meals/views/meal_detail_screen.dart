import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/macros.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import 'swap_sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'snooze_sheet.dart';

/// S08 meal detail route — replaces the S06 MealSheet stand-in. Day modes:
/// today = marking + snooze/swap/edit · future = inert checklist + swap/edit
/// (first content edit detaches the day, S05 §4.2) · past = read-only.
/// Status display ONLY via mealStatus; eligibility ONLY via the predicates.
class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  static const _guardMessage = "That can't be changed anymore.";

  Future<void> _run(
    BuildContext context,
    Future<void> Function() op, {
    bool pop = false,
  }) => runDayOp(context, op, guardMessage: _guardMessage, pop: pop);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final day = ref.watch(dayControllerProvider(date)).value;
    final meal = day?.meals.where((m) => m.id == mealId).firstOrNull;
    if (day == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (meal == null) {
      // Future-day preview ids are throwaway (S05 §4.2): a template edit
      // while this route is open re-mints them — degrade gracefully.
      return Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: context.pop,
                icon: Icon(
                  Icons.arrow_back,
                  size: IconSizes.lg,
                  color: colors.onSurface,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'This meal is no longer here.',
                    key: const ValueKey('meal-gone'),
                    style: CrudoText.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final isToday = date.isAtSameMomentAs(today);
    final isPast = date.isBefore(today);
    final status = mealStatus(day, mealId, now);
    final canEdit = canEditMealContent(meal, day.date, now);
    final ctrl = ref.read(dayControllerProvider(date).notifier);
    final tag = meal.meal.tags.isEmpty ? 'Meal' : meal.meal.tags.first.name;

    final items = meal.meal.items;
    final checkedCount = items.where((i) => i.checked).length;
    final isPartial = checkedCount > 0 && checkedCount < items.length;

    final snoozedLabel =
        meal.snoozedUntil != null &&
            (status == MealStatus.upcoming || status == MealStatus.overdue)
        ? '${mealTimeLabel(meal.time)} → ${timeOfDayLabel(meal.snoozedUntil!.toLocal())}'
        : mealTimeLabel(meal.time);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back · name + meta · Edit (gated by canEditMealContent).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.sm,
                Spacing.md,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: context.pop,
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.meal.name,
                          style: CrudoText.headlineSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$snoozedLabel · $tag · ${status.name}'.toUpperCase(),
                          style: CrudoText.label,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: canEdit ? 1 : Opacities.disabled,
                    child: IconButton(
                      key: const ValueKey('edit-meal'),
                      onPressed: () {
                        if (!canEdit) {
                          showCrudoToast(
                            context,
                            _guardMessage,
                            kind: ToastKind.warn,
                          );
                          return;
                        }
                        context.push('/meal/${dayParam(date)}/$mealId/edit');
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: IconSizes.md,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  Spacing.xl,
                ),
                children: [
                  _MacroSummary(macros: mealSnapshotMacros(meal.meal)),
                  const SizedBox(height: Spacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(
                        child: Text('Ingredients', style: CrudoText.headlineSm),
                      ),
                      Text(
                        '$checkedCount OF ${items.length} EATEN',
                        key: const ValueKey('eaten-count'),
                        style: CrudoText.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  _EatenProgress(
                    fraction: items.isEmpty ? 0 : checkedCount / items.length,
                    colors: colors,
                  ),
                  const SizedBox(height: Spacing.sm),
                  for (final (i, item) in items.indexed)
                    _ItemRow(
                      key: ValueKey('item-check-$i'),
                      name: item.food.name,
                      grams: item.food.grams.value,
                      kcal: item.food.kcal,
                      checked: item.checked,
                      colors: colors,
                      onTap: !isToday
                          ? null
                          : () => _run(
                              context,
                              () => item.checked
                                  ? ctrl.uncheckItem(mealId, i)
                                  : ctrl.checkItem(mealId, i),
                            ),
                    ),
                  if (!isPast) ...[
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        if (isToday) ...[
                          Expanded(
                            child: _ActionTile(
                              key: const ValueKey('tile-snooze'),
                              icon: Icons.snooze_outlined,
                              title: 'Snooze',
                              subtitle:
                                  '${snoozePresetMinutes.last}m delay, no further',
                              enabled: canSnoozeMeal(day, mealId, now, today),
                              colors: colors,
                              onTap: () => showCrudoSheet<void>(
                                context,
                                builder: (_) =>
                                    SnoozeSheet(date: date, mealId: mealId),
                              ),
                              onDisabledTap: () {
                                final reason = snoozeIneligibilityReason(
                                  day,
                                  mealId,
                                  now,
                                  today,
                                );
                                if (reason != null) {
                                  showCrudoToast(
                                    context,
                                    reason,
                                    kind: ToastKind.warn,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                        ],
                        Expanded(
                          child: _ActionTile(
                            key: const ValueKey('tile-swap'),
                            icon: Icons.swap_horiz,
                            title: 'Swap meal',
                            subtitle: 'Pick from library',
                            enabled: canEdit,
                            colors: colors,
                            onTap: () => showCrudoSheet<void>(
                              context,
                              builder: (_) =>
                                  SwapSheet(date: date, mealId: mealId),
                            ),
                            onDisabledTap: () => showCrudoToast(
                              context,
                              _guardMessage,
                              kind: ToastKind.warn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isToday
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryAction(
                        label: 'Skip',
                        enabled: canSkipMeal(day, mealId, today),
                        onTap: () => _run(
                          context,
                          () => ctrl.skipMeal(mealId),
                          pop: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      flex: 2,
                      child: PrimaryCta(
                        label: isPartial ? 'Save Partial' : 'Mark Done',
                        onPressed: checkedCount == 0
                            ? () => _run(
                                context,
                                () => ctrl.markAllEaten(mealId),
                                pop: true,
                              )
                            : () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Total-intake card (meal.jsx 33–51): big kcal + three macro mini-tiles.
class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.macros});

  final Macros macros;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final tiles = [
      ('PROTEIN', macros.protein, colors.proteinColor),
      ('CARBS', macros.carbs, colors.carbsColor),
      ('FATS', macros.fats, colors.fatsColor),
    ];
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL INTAKE', style: CrudoText.label),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${macros.kcal.round()}',
                key: const ValueKey('detail-kcal'),
                style: CrudoText.display,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'kcal',
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              for (final (label, value, accent) in tiles) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: Radii.all(Radii.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: CrudoText.label),
                        const SizedBox(height: Spacing.xs),
                        Text.rich(
                          TextSpan(
                            text: '${value.round()}',
                            style: CrudoText.title.copyWith(color: accent),
                            children: [
                              TextSpan(
                                text: 'g',
                                style: CrudoText.label.copyWith(
                                  color: colors.onSurfaceMut,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (label != 'FATS') const SizedBox(width: Spacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Thin eaten-fraction bar. Height = 4 (4px grid; design_system §5).
class _EatenProgress extends StatelessWidget {
  const _EatenProgress({required this.fraction, required this.colors});

  final double fraction;
  final CrudoColors colors;

  static const _height = 4.0; // component size, 4px grid (§5)

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: Radii.all(Radii.full),
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            Expanded(
              flex: (fraction * 1000).round(),
              child: ColoredBox(color: colors.primary),
            ),
            Expanded(
              flex: ((1 - fraction) * 1000).round(),
              child: ColoredBox(color: colors.surfaceLow),
            ),
          ],
        ),
      ),
    );
  }
}

// _ItemRow, _CheckCircle, _CheckRingPainter, _ActionTile: shared sheet
// widgets (originally from the S06 MealSheet, now owned here).

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.checked,
    required this.colors,
    this.onTap,
    super.key,
  });

  final String name;
  final double grams;
  final double kcal;
  final bool checked;
  final CrudoColors colors;
  final VoidCallback? onTap;

  static const _checkSize = 28.0; // design system §5 — check circle

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      toggled: checked,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Row(
            children: [
              _CheckCircle(checked: checked, size: _checkSize),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  name,
                  style: CrudoText.body.copyWith(color: colors.onSurface),
                ),
              ),
              Text(
                '${grams.round()}g · ${kcal.round()} kcal',
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked, required this.size});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return CustomPaint(
      painter: checked ? null : _CheckRingPainter(colors.outline),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: checked ? colors.primary : colors.surfaceLowest,
          shape: BoxShape.circle,
        ),
        child: checked
            ? Icon(Icons.check, size: IconSizes.md, color: colors.surfaceLowest)
            : null,
      ),
    );
  }
}

/// Painted ring for the unchecked check-circle (no-line rule: never a Border).
class _CheckRingPainter extends CustomPainter {
  const _CheckRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 - 1,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_CheckRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// meal.jsx 91–106 action tile: icon + title + subtitle, muted when disabled.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.enabled = true,
    this.onTap,
    this.onDisabledTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final CrudoColors colors;
  final bool enabled;
  final VoidCallback? onTap;

  /// Fires when the tile is tapped while disabled (S05.1: ineligibility
  /// toast). The tile still renders at Opacities.disabled — never hides.
  final VoidCallback? onDisabledTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : Opacities.disabled,
      child: Semantics(
        button: enabled && onTap != null,
        label: title,
        child: GestureDetector(
          onTap: enabled ? onTap : onDisabledTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLow,
              borderRadius: Radii.all(Radii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: IconSizes.md, color: colors.primary),
                const SizedBox(height: Spacing.xs),
                Text(
                  title,
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
