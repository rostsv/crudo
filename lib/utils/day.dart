// Generic calendar helpers. Pure and domain-free — business rules about days
// (plan-day assignment, midnight-lock) live in domain/application (S05).

/// Midnight-normalized copy, preserving the input's local/UTC frame.
DateTime dayKey(DateTime dt) => dt.isUtc
    ? DateTime.utc(dt.year, dt.month, dt.day)
    : DateTime(dt.year, dt.month, dt.day);

/// True when both instants fall on the same calendar date. Both arguments are
/// expected in the same frame (both local or both UTC).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Weekday as 0=Mon … 6=Sun (the PlanTemplate.days convention). Dart's
/// DateTime.weekday is 1=Mon … 7=Sun.
int weekdayIndex(DateTime dt) => dt.weekday - 1;

/// The date [n] days from [dt] (may be negative), midnight-normalized.
/// Uses date-component arithmetic, not Duration — safe across DST shifts.
DateTime addDays(DateTime dt, int n) => dt.isUtc
    ? DateTime.utc(dt.year, dt.month, dt.day + n)
    : DateTime(dt.year, dt.month, dt.day + n);

/// Converts a real UTC instant to the user's local calendar date, encoded as
/// a UTC-midnight DateTime — the canonical `Day.date` label form.
DateTime localDayLabel(DateTime utcInstant) {
  final local = utcInstant.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}
