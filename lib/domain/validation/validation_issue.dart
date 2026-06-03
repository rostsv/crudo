/// Machine-readable reason a save-time validation failed. The UI maps [code]
/// to localized text; [message] is a developer-readable fallback.
enum ValidationCode {
  blankName,
  blankId,
  blankMealTemplateId,
  kcalOverrideOutOfRange,
  macroMassExceeded,
  emptyMeal,
  emptyActivePlan,
  invalidThreshold,
  nonPositiveTarget,
  preMinTooLarge,
  duplicateMealId,
  duplicateWeekday,
  invalidWeekday,
}

class ValidationIssue {
  const ValidationIssue({
    required this.field,
    required this.code,
    required this.message,
  });

  final String field;
  final ValidationCode code;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ValidationIssue &&
      other.field == field &&
      other.code == code &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, code, message);

  @override
  String toString() => 'ValidationIssue($field, $code, $message)';
}
