import 'package:freezed_annotation/freezed_annotation.dart';

import '../meal/meal.dart';
import '../shared/enums.dart';

part 'day.freezed.dart';

/// A materialized day (instance tree, aggregate root): the user's local
/// calendar date + that day's snapshot meals. ONE type serves today, future,
/// and history — "locked" is derived from the date (past = locked at local
/// midnight, S05). `adherence` + `state` are null while the day is open and
/// written exactly once at midnight-lock (S12), so later threshold changes
/// can't recolor history. `date` is a date LABEL: the local calendar date
/// encoded as DateTime.utc(y, m, d). Real instants elsewhere are true UTC.
/// NOTE: the factory is deliberately NON-const — a const Day is impossible
/// anyway (DateTime is never const-creatable), and a non-const constructor
/// lets the @Assert invariants use DateTime property access, which Dart
/// forbids in const-constructor asserts.
@freezed
abstract class Day with _$Day {
  const Day._();

  @Assert('date.isUtc', 'date must be the UTC-encoded local-date label')
  @Assert(
    'date.hour == 0 && date.minute == 0 && date.second == 0 && '
        'date.millisecond == 0 && date.microsecond == 0',
    'date must be midnight-normalized',
  )
  @Assert(
    '(adherence == null) == (state == null)',
    'adherence and state are frozen together at lock',
  )
  @Assert(
    'adherence == null || (adherence >= 0 && adherence <= 1)',
    'adherence must be within [0,1]',
  )
  factory Day({
    required DateTime date,
    String? sourcePlanId,
    String? planName,
    @Default(<Meal>[]) List<Meal> meals,
    double? adherence,
    DayState? state,
  }) = _Day;
}
