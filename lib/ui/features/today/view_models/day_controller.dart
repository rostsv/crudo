import 'dart:async';

import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'today_providers.dart';

part 'day_controller.g.dart';

/// Day resolution per S05 §4.3 — the contract the engine left to S06:
/// repo hit wins (snapshot authoritative, never re-materialized) → past
/// miss = empty locked day → otherwise build from plan; today persists
/// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
/// them); future days stay pure previews (template edits flow through).
@riverpod
class DayController extends _$DayController {
  @override
  Future<Day> build(DateTime date) async {
    final today = ref.watch(todayProvider);
    final persisted = await ref.watch(persistedDayProvider(date).future);
    if (persisted != null) return persisted;
    if (date.isBefore(today)) return Day(date: date); // never-opened past day

    // Independent reads — resolved in parallel (matters once S20 puts
    // real latency behind the repositories).
    final (plans, templates, library) = await (
      ref.watch(planTemplatesProvider.future),
      ref.watch(mealTemplatesProvider.future),
      ref.watch(foodsProvider.future),
    ).wait;
    final built = buildDayFromPlan(
      selectPlanForDate(plans, date),
      date,
      ref.read(idGeneratorProvider).newId,
      templates,
      library,
    );
    if (date.isAtSameMomentAs(today)) {
      // Eager persist: the save re-emits through persistedDayProvider and
      // this provider settles on the snapshot.
      await ref.read(dayRepositoryProvider).save(built);
    }
    return built;
  }

  Future<void> checkItem(String mealId, int itemIndex) =>
      _apply((d, now, today) => d.checkItem(mealId, itemIndex, now, today));

  Future<void> uncheckItem(String mealId, int itemIndex) =>
      _apply((d, now, today) => d.uncheckItem(mealId, itemIndex, now, today));

  Future<void> markAllEaten(String mealId) =>
      _apply((d, now, today) => d.markAllEaten(mealId, now, today));

  Future<void> skipMeal(String mealId) =>
      _apply((d, now, today) => d.skipMeal(mealId, now, today));

  Future<void> unmarkAll(String mealId) =>
      _apply((d, now, today) => d.unmarkAll(mealId, today));

  Future<void> snooze(String mealId, DateTime until) =>
      _apply((d, now, today) => d.snoozeMeal(mealId, until, now, today));

  /// Content op (S08): allowed for today AND future days — saving a
  /// future-day preview IS the copy-on-write detach (S05 §4.3: the repo
  /// hit wins on every later read; template edits no longer touch it).
  /// Past days reject. Marking/skip/snooze stay today-only (_apply).
  Future<void> replaceMeal(String mealId, MealSnapshot newMeal) =>
      _applyContent(
        (d, now, today) => d.replaceMeal(mealId, newMeal, now, today),
      );

  Future<void> _applyContent(
    Day Function(Day day, DateTime now, DateTime today) op,
  ) async {
    final today = ref.read(todayProvider);
    if (date.isBefore(today)) {
      throw StateError('day $date is read-only (today is $today)');
    }
    final day = await future;
    final now = ref.read(clockProvider)();
    await ref.read(dayRepositoryProvider).save(op(day, now, today));
  }

  /// All ops are today-only in S06 (future-day edits = the S08 detach
  /// path; past days are locked by the domain anyway). Guard violations
  /// throw StateError — views pre-check with meal_lifecycle predicates
  /// and catch the rest into a toast.
  Future<void> _apply(
    Day Function(Day day, DateTime now, DateTime today) op,
  ) async {
    final today = ref.read(todayProvider);
    if (!date.isAtSameMomentAs(today)) {
      throw StateError('day $date is read-only (today is $today)');
    }
    final day = await future;
    final now = ref.read(clockProvider)();
    await ref.read(dayRepositoryProvider).save(op(day, now, today));
  }
}
