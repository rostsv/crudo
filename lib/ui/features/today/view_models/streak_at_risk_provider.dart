import 'package:crudo/config/di.dart';
import 'package:crudo/domain/services/notification_schedule.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'day_controller.dart';
import 'notification_scheduler_controller.dart';
import 'today_providers.dart';

part 'streak_at_risk_provider.g.dart';

/// In-app streak-at-risk banner data, or null when safe / lost / muted.
typedef StreakRisk = ({
  int streakDays,
  int mealsLeft,
  String pivotalMealName,
  MealTime pivotalMealTime,
  int minutesFromNow,
});

@riverpod
Future<StreakRisk?> streakAtRisk(Ref ref) async {
  final today = ref.watch(todayProvider);
  if (ref.watch(mutedRiskDayProvider) == today) return null;
  final day = await ref.watch(dayControllerProvider(today).future);
  // Watch (not read-once) so a threshold edit (S15) re-evaluates risk now.
  final profile = await ref.watch(profileProvider.future);
  final streak = await ref.read(streakRepositoryProvider).get();
  final now = ref.read(clockProvider)();
  final info = streakRiskInfo(day, profile.prefs.streakThreshold, now);
  if (info == null) return null;
  final mins = info.deadline.difference(now.toUtc()).inMinutes;
  return (
    streakDays: streak.current,
    mealsLeft: info.mealsLeft,
    pivotalMealName: info.pivotalMealName,
    pivotalMealTime: info.pivotalMealTime,
    minutesFromNow: mins < 0 ? 0 : mins,
  );
}
