import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../view_models/day_controller.dart';
import '../view_models/today_providers.dart';
import 'formatting.dart';
import 'sheet_actions.dart';
import 'snooze_sheet.dart';

/// Opens the inline marking sheet for one scheduled meal of one day (the
/// S06 stand-in for the S08 mealDetail route). [readOnly] renders the
/// checklist without any mutating controls — used for past days.
Future<void> showMealSheet(
  BuildContext context, {
  required DateTime date,
  required String mealId,
  bool readOnly = false,
}) {
  return showCrudoSheet<void>(
    context,
    builder: (_) => MealSheet(date: date, mealId: mealId, readOnly: readOnly),
  );
}

/// Marking sheet: watches the day controller so the checklist and derived
/// status re-render live as items toggle. Body: checklist + action tiles
/// (Snooze, Swap stub). Footer: Skip + dynamic primary (Mark Done / Save
/// Partial). Read-only mode hides all actions.
class MealSheet extends ConsumerWidget {
  const MealSheet({
    required this.date,
    required this.mealId,
    this.readOnly = false,
    super.key,
  });

  final DateTime date;
  final String mealId;
  final bool readOnly;

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
    if (day == null || meal == null) return const SizedBox.shrink();

    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final status = mealStatus(day, mealId, now);
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

    return SheetScaffold(
      label: '$snoozedLabel · $tag · ${status.name}',
      title: meal.meal.name,
      body: ListView(
        shrinkWrap: true,
        children: [
          for (final (i, item) in meal.meal.items.indexed)
            _ItemRow(
              key: ValueKey('item-check-$i'),
              name: item.food.name,
              grams: item.food.grams.value,
              kcal: item.food.kcal,
              checked: item.checked,
              colors: colors,
              onTap: readOnly
                  ? null
                  : () => _run(
                      context,
                      () => item.checked
                          ? ctrl.uncheckItem(mealId, i)
                          : ctrl.checkItem(mealId, i),
                    ),
            ),
          if (!readOnly) ...[
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    key: const ValueKey('tile-snooze'),
                    icon: Icons.snooze_outlined,
                    title: 'Snooze',
                    subtitle: '${snoozePresetMinutes.last}m delay, no further',
                    enabled: canSnoozeMeal(day, mealId, now, today),
                    colors: colors,
                    onTap: () => showCrudoSheet<void>(
                      context,
                      builder: (_) => SnoozeSheet(date: date, mealId: mealId),
                    ),
                    onDisabledTap: () {
                      final reason = snoozeIneligibilityReason(
                        day,
                        mealId,
                        now,
                        today,
                      );
                      if (reason != null) {
                        showCrudoToast(context, reason, kind: ToastKind.warn);
                      }
                    },
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _ActionTile(
                    key: const ValueKey('tile-swap'),
                    icon: Icons.swap_horiz,
                    title: 'Swap meal',
                    subtitle: 'Pick from library',
                    colors: colors,
                    // TODO(S08): meal-library picker — design stub until then.
                    onTap: null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      cta: readOnly
          ? null
          : Row(
              children: [
                Expanded(
                  child: SecondaryAction(
                    label: 'Skip',
                    enabled: canSkipMeal(day, mealId, today),
                    onTap: () =>
                        _run(context, () => ctrl.skipMeal(mealId), pop: true),
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
                        : () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
    );
  }
}

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
