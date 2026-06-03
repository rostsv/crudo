import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak.freezed.dart';

/// Calorie-based streak state (architecture §10). Shape only — +1/hold/reset
/// transitions and milestone badges (7/30/100) are S12. `lastCountedDay` is a
/// UTC-encoded local-date label, used for reset detection.
@freezed
abstract class Streak with _$Streak {
  const Streak._();

  @Assert('current >= 0', 'current must be >= 0')
  @Assert('personalBest >= 0', 'personalBest must be >= 0')
  @Assert('personalBest >= current', 'personalBest cannot be below current')
  const factory Streak({
    @Default(0) int current,
    @Default(0) int personalBest,
    DateTime? lastCountedDay,
  }) = _Streak;
}
