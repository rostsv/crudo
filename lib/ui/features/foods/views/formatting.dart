// Formatting helpers shared across food-feature views (S07).
// Mirrors the pattern of lib/ui/features/today/views/formatting.dart:
// pure functions, no Flutter/Riverpod imports.

/// Trims trailing ".0" — "3.6" stays "3.6", "31.0" renders as "31".
String gramsText(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Normalises a user-typed number string (comma or dot decimal) and parses
/// it. Returns null when the string is not a valid number.
///
/// Example: parseGrams('12,5') → 12.5; parseGrams('350.5') → 350.5.
double? parseGrams(String s) => double.tryParse(s.replaceAll(',', '.'));

/// Percentage string for the kcal mismatch banner. Shows one decimal place
/// when the rounded integer would equal 10 (to avoid "10%" looking exact
/// when the real value is 10.3 or similar). Ceils to one decimal in that
/// branch so the displayed value never understates the bound violation.
///
/// Example: pctText(10.025) → '10.1'; pctText(10.34) → '10.4';
///          pctText(9.0) → '9'; pctText(21.0) → '21'.
String pctText(double pct) {
  final rounded = pct.round();
  if (rounded == 10 && pct != 10.0) {
    // Ceil to one decimal: displayed pct must never understate the violation.
    final oneDecimalCeil = (pct * 10).ceilToDouble() / 10;
    return oneDecimalCeil.toStringAsFixed(1);
  }
  return '$rounded';
}
