import 'package:crudo/config/di.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_providers.g.dart';

/// Injectable wall clock — overridden in every test for deterministic time.
/// The domain never reads a clock (S05 §5); only providers do, through this.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The current local calendar day as a UTC day-label (S02 convention).
/// Re-derived via [refresh] on app resume + the midnight tick (TodayScreen
/// owns the observer/timer); never advances on its own.
@riverpod
class Today extends _$Today {
  @override
  DateTime build() => localDateLabel(ref.read(clockProvider)());

  void refresh() {
    final next = localDateLabel(ref.read(clockProvider)());
    if (next != state) state = next;
  }
}

/// The day the UI is looking at. Follows today (snaps back on rollover —
/// watch dependency) until the user picks another date in the week strip.
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => ref.watch(todayProvider);

  void select(DateTime date) => state = date;
}

/// Streak count for the chip. Stub data until S12 writes real streaks —
/// the provider contract is final, only the data source matures.
@riverpod
Stream<int> streakCount(Ref ref) =>
    ref.watch(streakRepositoryProvider).watch().map((s) => s.current);

@riverpod
Stream<UserProfile> profile(Ref ref) =>
    ref.watch(profileRepositoryProvider).watch();

/// The persisted Day snapshot for a date — null while the repo has no row.
/// Repo presence is the authoritative bit of the S05 §4.3 read path.
@riverpod
Stream<Day?> persistedDay(Ref ref, DateTime date) =>
    ref.watch(dayRepositoryProvider).watchByDate(date);

@riverpod
Stream<List<PlanTemplate>> planTemplates(Ref ref) =>
    ref.watch(planTemplateRepositoryProvider).watchAll();

@riverpod
Stream<List<MealTemplate>> mealTemplates(Ref ref) =>
    ref.watch(mealTemplateRepositoryProvider).watchAll();

@riverpod
Stream<List<Food>> foods(Ref ref) =>
    ref.watch(foodRepositoryProvider).watchAll();
