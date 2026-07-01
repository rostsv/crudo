import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/meal/meal_item.dart';
import '../../../../domain/meal/meal_snapshot.dart';
import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/macros.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/macro_chip.dart';
import '../../../core/widgets/macro_total_card.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'meal_actions_sheet.dart';

/// S08 meal detail route — replaces the S06 MealSheet stand-in. Day modes:
/// today = marking + snooze/swap/edit · future = inert checklist + swap/edit
/// (first content edit detaches the day, S05 §4.2) · past = read-only.
/// Status display ONLY via mealStatus; eligibility ONLY via the predicates.
///
/// Check state is a local draft until the user taps [Log meal]. Leaving the
/// screen without logging discards the draft.
class MealDetailScreen extends ConsumerStatefulWidget {
  const MealDetailScreen({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  static const _guardMessage = "That can't be changed anymore.";

  /// Local draft of checked ingredient indices. `null` until the persisted
  /// meal first resolves; seeded from existing checked items so re-opening a
  /// logged meal shows its state. Once the user touches a check or the
  /// check-all toggle, [_userChanged] locks the draft and it is no longer
  /// reseeded from persisted state.
  Set<int>? _draft;
  bool _userChanged = false;

  Set<int> _persistedChecked(MealSnapshot meal) => {
    for (final (i, item) in meal.items.indexed)
      if (item.checked) i,
  };

  Future<void> _run(
    BuildContext context,
    Future<void> Function() op, {
    bool pop = false,
  }) => runDayOp(context, op, guardMessage: _guardMessage, pop: pop);

  void _toggleDraft(int index) {
    setState(() {
      _userChanged = true;
      _draft = {...?_draft}..toggle(index);
    });
  }

  void _toggleCheckAll(int itemCount) {
    setState(() {
      _userChanged = true;
      _draft = _draft!.length == itemCount
          ? <int>{}
          : {for (var i = 0; i < itemCount; i++) i};
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final dayAsync = ref.watch(dayControllerProvider(widget.date));
    final day = dayAsync.value;
    final meal = day?.meals.where((m) => m.id == widget.mealId).firstOrNull;

    if (dayAsync.isLoading || dayAsync.hasError || day == null) {
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
              const Expanded(
                child: Center(
                  child: Text(
                    'This meal is no longer here.',
                    key: ValueKey('meal-gone'),
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
    final isToday = widget.date.isAtSameMomentAs(today);
    final status = mealStatus(day, widget.mealId, now);
    final canEdit = canEditMealContent(meal, day.date, now);
    final ctrl = ref.read(dayControllerProvider(widget.date).notifier);
    final tag = meal.meal.tags.isEmpty ? 'Meal' : meal.meal.tags.first.name;

    final items = meal.meal.items;

    // Seed the draft from persisted state whenever it resolves, until the
    // user has interacted with it.
    if (!_userChanged) {
      _draft = _persistedChecked(meal.meal);
    }
    final draft = _draft!;
    final persistedChecked = _persistedChecked(meal.meal);
    final canLog = !setEquals(draft, persistedChecked);

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
                            body:
                                'This meal is already logged, skipped, or locked.',
                            kind: ToastKind.warn,
                          );
                          return;
                        }
                        context.push(
                          '/meal/${dayParam(widget.date)}/${widget.mealId}/edit',
                        );
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
                  _MacroSummary(
                    macros: mealSnapshotMacros(meal.meal),
                    tags: meal.meal.tags,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(
                        child: Text('Ingredients', style: CrudoText.headlineSm),
                      ),
                      if (isToday && items.isNotEmpty) ...[
                        _CheckAllToggle(
                          allChecked: draft.length == items.length,
                          colors: colors,
                          onTap: () => _toggleCheckAll(items.length),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  _EatenProgress(
                    fraction: _eatenKcalFraction(items, draft),
                    colors: colors,
                  ),
                  const SizedBox(height: Spacing.sm),
                  ClipRRect(
                    borderRadius: Radii.all(Radii.lg),
                    child: Column(
                      children: [
                        for (final (i, item) in items.indexed)
                          ColoredBox(
                            key: ValueKey('item-row-$i'),
                            color: i.isEven
                                ? colors.surface
                                : colors.surfaceLow,
                            child: _ItemRow(
                              key: ValueKey('item-check-$i'),
                              name: item.food.name,
                              grams: item.food.grams.value,
                              kcal: item.food.kcal,
                              protein: item.food.protein,
                              carbs: item.food.carbs,
                              fats: item.food.fats,
                              checked: draft.contains(i),
                              colors: colors,
                              onTap: !isToday ? null : () => _toggleDraft(i),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryCta(
                        label: 'Log meal',
                        enabled: canLog,
                        onPressed: canLog
                            ? () async {
                                final wouldUndoDone =
                                    meal.meal.allChecked &&
                                    draft.length < items.length;
                                if (wouldUndoDone) {
                                  final confirmed =
                                      await showModifyDoneMealConfirmSheet(
                                        context,
                                      );
                                  if (confirmed != true || !context.mounted) {
                                    return;
                                  }
                                }
                                await _run(
                                  context,
                                  () => ctrl.logMeal(widget.mealId, draft),
                                  pop: true,
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    IconButton(
                      key: const ValueKey('meal-actions'),
                      onPressed: () => showCrudoSheet<void>(
                        context,
                        builder: (_) => MealActionsSheet(
                          date: widget.date,
                          mealId: widget.mealId,
                        ),
                      ),
                      icon: Icon(
                        Icons.more_vert,
                        size: IconSizes.lg,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Total-intake card: [MacroTotalCard] (tonal) with the meal's tag pills
/// passed as the footer slot.
class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.macros, required this.tags});

  final Macros macros;
  final List<MealTag> tags;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return MacroTotalCard(
      macros: macros,
      label: 'TOTAL INTAKE',
      footer: tags.isEmpty
          ? null
          : Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: [
                for (final tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: Radii.all(Radii.full),
                    ),
                    child: Text(
                      tag.name.toUpperCase(),
                      style: CrudoText.label.copyWith(
                        color: colors.surfaceLowest,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Thin eaten-fraction bar under the ingredient list. Height = 4 (4px grid;
/// design_system §5). The filled portion animates smoothly when the draft
/// changes.
class _EatenProgress extends StatelessWidget {
  const _EatenProgress({required this.fraction, required this.colors});

  final double fraction;
  final CrudoColors colors;

  static const _height = 4.0; // component size, 4px grid (§5)

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          key: const ValueKey('eaten-progress-track'),
          borderRadius: Radii.all(Radii.full),
          child: SizedBox(
            height: _height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: colors.surfaceLow)),
                AnimatedContainer(
                  key: const ValueKey('eaten-progress-fill'),
                  duration: dim.Durations.slow,
                  curve: Curves.easeInOut,
                  width: (fraction * constraints.maxWidth).clamp(
                    0,
                    constraints.maxWidth,
                  ),
                  height: _height,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        );
      },
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
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.checked,
    required this.colors,
    this.onTap,
    super.key,
  });

  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fats;
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
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.sm,
            horizontal: Spacing.sm,
          ),
          child: Row(
            // Centers the check circle against the full two-line block
            // (name+trailing, then macro dots), not just the first line.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CheckCircle(checked: checked, size: _checkSize),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: dim.Durations.fast,
                            curve: Curves.easeOut,
                            style: checked
                                ? CrudoText.body.copyWith(
                                    color: colors.onSurfaceMut,
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : CrudoText.body.copyWith(
                                    color: colors.onSurface,
                                  ),
                            child: Text(name),
                          ),
                        ),
                        Text(
                          '${grams.round()}g · ${kcal.round()} kcal',
                          style: CrudoText.body.copyWith(
                            color: colors.onSurfaceMut,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        MacroChip(grams: protein, color: colors.proteinColor),
                        const SizedBox(width: Spacing.sm),
                        MacroChip(grams: carbs, color: colors.carbsColor),
                        const SizedBox(width: Spacing.sm),
                        MacroChip(grams: fats, color: colors.fatsColor),
                      ],
                    ),
                  ],
                ),
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
      // Foreground, not background: a `painter` layer paints behind the
      // child and is fully hidden by the opaque same-size filled circle.
      // Mid-gray ring on both states so the circle contrasts against the
      // background even when filled, without going full-dark.
      foregroundPainter: _CheckRingPainter(
        colors.onSurfaceMut.withValues(alpha: 0.55),
      ),
      child: AnimatedContainer(
        duration: dim.Durations.fast,
        curve: Curves.easeOut,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: checked ? colors.primary : colors.surfaceLowest,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: dim.Durations.fast,
          child: checked
              ? Icon(
                  Icons.check,
                  key: const ValueKey('check-icon'),
                  size: IconSizes.md,
                  color: colors.surfaceLowest,
                )
              : const SizedBox.shrink(key: ValueKey('check-icon-empty')),
        ),
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
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CheckRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Small "check all / uncheck all" toggle in the ingredients header (today
/// only). Operates on the local draft only — nothing persists until
/// [DayController.logMeal] is invoked via the Log meal button.
class _CheckAllToggle extends StatelessWidget {
  const _CheckAllToggle({
    required this.allChecked,
    required this.colors,
    required this.onTap,
  });

  final bool allChecked;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = allChecked ? 'Uncheck all' : 'Check all';
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const ValueKey('check-all-toggle'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allChecked ? Icons.clear : Icons.done_all,
                size: IconSizes.sm,
                color: colors.primary,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                label.toUpperCase(),
                style: CrudoText.label.copyWith(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eaten fraction by kcal share (not item count) — mirrors the kcal hero /
/// TOTAL INTAKE card so "half eaten" means half the calories, not half the
/// ingredients.
double _eatenKcalFraction(List<MealItem> items, Set<int> draft) {
  final totalKcal = items.fold<double>(0, (sum, item) => sum + item.food.kcal);
  if (totalKcal <= 0) return 0;
  final checkedKcal = items.indexed
      .where((entry) => draft.contains(entry.$1))
      .fold<double>(0, (sum, entry) => sum + entry.$2.food.kcal);
  return checkedKcal / totalKcal;
}

extension on Set<int> {
  void toggle(int value) {
    if (contains(value)) {
      remove(value);
    } else {
      add(value);
    }
  }
}
