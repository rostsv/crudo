import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';

part 'prefs.freezed.dart';

/// User settings. `dailyKcalTarget` is the onboarding "how many calories a
/// day?" number — build-time GUIDANCE only; adherence is always computed
/// consumed ÷ planned-products (architecture §10), never against this target.
/// `streakThreshold` is the green line (70/80/90/100, default 80); red floor
/// fixed at 50, not stored. Set membership is user-facing validation.
@freezed
abstract class Prefs with _$Prefs {
  const Prefs._();

  @Assert('preMin >= 0', 'preMin must be >= 0')
  const factory Prefs({
    @Default(Goal.maintain) Goal goal,
    @Default(Unit.g) Unit units,
    int? dailyKcalTarget,
    @Default(80) int streakThreshold,
    @Default(ReminderMode.fixed) ReminderMode reminderMode,
    @Default(true) bool preOn,
    @Default(true) bool atOn,
    @Default(true) bool eodOn,
    @Default(true) bool riskOn,
    @Default(30) int preMin,
  }) = _Prefs;
}
