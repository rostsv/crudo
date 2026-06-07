import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/day/day.dart';
import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/meal_status.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/meal_card.dart';
import '../../../core/widgets/toast.dart';
import '../view_models/day_controller.dart';
import '../view_models/intake_freeze.dart';
import '../view_models/today_providers.dart';
import 'day_strip.dart';
import 'formatting.dart';
import 'intake_card.dart';
import 'meal_sheet.dart';
import 'nudge_card.dart';
import 'sheet_actions.dart';
import 'streak_chip.dart';

/// The Today tab (S06 spec): appbar (date + greeting + calendar stub) ·
/// Mon–Sun strip · intake hero with floating streak chip · meal list with
/// the marking sheet · end-of-day nudge. Marking is today-only; past days
/// open the sheet read-only; future days are pure previews (not tappable).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightTick();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may have crossed midnight while backgrounded — re-derive
      // today; locking is date-derived so intervening days lock retroactively
      // (S05 §4.4).
      ref.read(todayProvider.notifier).refresh();
      _scheduleMidnightTick();
    }
  }

  /// Rollover is derived, never timed in the domain (S05 §4.4) — this timer
  /// only pokes todayProvider when local midnight passes with the app open.
  void _scheduleMidnightTick() {
    _midnightTimer?.cancel();
    final now = ref.read(clockProvider)();
    final nextMidnight = endOfDayLocal(localDateLabel(now));
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        ref.read(todayProvider.notifier).refresh();
        _scheduleMidnightTick();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final today = ref.watch(todayProvider);
    final selected = ref.watch(selectedDateProvider);
    final dayAsync = ref.watch(dayControllerProvider(selected));
    final profile = ref.watch(profileProvider).value;
    final streak = ref.watch(streakCountProvider).value ?? 0;
    final frozen = ref.watch(intakeFreezeProvider);
    final now = ref.read(clockProvider)();
    final isToday = selected.isAtSameMomentAs(today);
    final isPast = selected.isBefore(today);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.md,
          Spacing.md,
          Spacing.xxl,
        ),
        children: [
          _AppBar(
            dateLabel: dateHeadline(selected),
            greeting: greetingFor(now, profile?.displayName),
            onCalendarTap: () =>
                showCrudoToast(context, 'Calendar — coming soon'),
          ),
          const SizedBox(height: Spacing.md),
          DayStrip(
            dates: weekOf(today),
            selected: selected,
            today: today,
            onSelect: ref.read(selectedDateProvider.notifier).select,
          ),
          const SizedBox(height: Spacing.lg),
          ...dayAsync.when(
            loading: () => const [SizedBox.shrink()],
            error: (e, _) => [
              Center(
                child: Text('Something went wrong', style: CrudoText.body),
              ),
            ],
            data: (day) => [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IntakeCard(
                    consumed: frozen ?? consumedMacros(day),
                    planned: plannedMacros(day),
                  ),
                  Positioned(
                    top: -Spacing.sm,
                    right: Spacing.lg,
                    child: StreakChip(count: streak),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              if (day.meals.isEmpty)
                _EmptyState(
                  message: isPast
                      ? 'No data for this day.'
                      : 'Rest day — nothing planned.',
                  colors: colors,
                )
              else ...[
                _MealsHeader(day: day, now: now),
                const SizedBox(height: Spacing.sm),
                for (final meal in day.meals) ...[
                  Builder(
                    builder: (context) {
                      final status = mealStatus(day, meal.id, now);
                      final snoozed =
                          meal.snoozedUntil != null &&
                              (status == MealStatus.upcoming ||
                                  status == MealStatus.overdue)
                          ? timeOfDayLabel(meal.snoozedUntil!.toLocal())
                          : null;
                      final tags = meal.meal.tags;
                      return MealCard(
                        title: meal.meal.name,
                        timeLabel: mealTimeLabel(meal.time),
                        snoozedTimeLabel: snoozed,
                        mealTypeLabel: tags.isEmpty
                            ? 'Meal'
                            : tags.first.name[0].toUpperCase() +
                                  tags.first.name.substring(1),
                        macros: mealSnapshotMacros(meal.meal),
                        ingredientNames: [
                          for (final i in meal.meal.items) i.food.name,
                        ],
                        status: status,
                        onTap: selected.isAfter(today)
                            ? null
                            : () {
                                if (isToday) {
                                  ref
                                      .read(intakeFreezeProvider.notifier)
                                      .freeze(consumedMacros(day));
                                }
                                showMealSheet(
                                  context,
                                  date: selected,
                                  mealId: meal.id,
                                  readOnly: !isToday,
                                ).whenComplete(() {
                                  if (isToday) {
                                    ref
                                        .read(intakeFreezeProvider.notifier)
                                        .clear();
                                  }
                                });
                              },
                        onStatusTap: !isToday
                            ? null
                            : () {
                                final ctrl = ref.read(
                                  dayControllerProvider(selected).notifier,
                                );
                                runDayOp(
                                  context,
                                  () => status == MealStatus.done
                                      ? ctrl.unmarkAll(meal.id)
                                      : ctrl.markAllEaten(meal.id),
                                  guardMessage:
                                      "That can't be changed anymore.",
                                );
                              },
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
                if (isToday) _nudge(day, now),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _nudge(Day day, DateTime now) {
    final planned = plannedKcal(day);
    final consumed = consumedKcal(day);
    final remaining = day.meals.where((m) {
      final s = mealStatus(day, m.id, now);
      return s == MealStatus.upcoming || s == MealStatus.overdue;
    }).length;
    if (planned <= 0 || remaining == 0) return const SizedBox.shrink();
    final pct = (consumed / planned * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: NudgeCard(
        title: "You're $pct% of the way there.",
        body: remaining == 1
            ? 'One meal remains. A done day keeps the streak.'
            : '$remaining meals remain. A done day keeps the streak.',
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.dateLabel,
    required this.greeting,
    required this.onCalendarTap,
  });

  final String dateLabel;
  final String greeting;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLabel.toUpperCase(), style: CrudoText.label),
              const SizedBox(height: Spacing.xs),
              Text(greeting, style: CrudoText.headlineSm),
            ],
          ),
        ),
        IconButton(
          onPressed: onCalendarTap,
          icon: Icon(
            Icons.calendar_today_outlined,
            size: IconSizes.md,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MealsHeader extends StatelessWidget {
  const _MealsHeader({required this.day, required this.now});

  final Day day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    var done = 0;
    var partial = 0;
    for (final m in day.meals) {
      switch (mealStatus(day, m.id, now)) {
        case MealStatus.done:
          done++;
        case MealStatus.partial:
          partial++;
        case MealStatus.upcoming || MealStatus.overdue || MealStatus.skipped:
          break;
      }
    }
    final counts = partial > 0
        ? '$done/${day.meals.length} complete · $partial partial'
        : '$done/${day.meals.length} complete';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text('Meals', style: CrudoText.headline)),
        Text(counts, style: CrudoText.label),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.colors});

  final String message;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
      child: Center(
        child: Text(
          message,
          style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
        ),
      ),
    );
  }
}
