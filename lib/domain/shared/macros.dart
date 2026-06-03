import 'package:freezed_annotation/freezed_annotation.dart';

part 'macros.freezed.dart';

/// Derived macro totals (protein/carbs/fats grams + kcal). Never persisted —
/// always recomputed from products (architecture §6), hence no JSON.
@freezed
abstract class Macros with _$Macros {
  const Macros._();

  const factory Macros({
    @Default(0) double protein,
    @Default(0) double carbs,
    @Default(0) double fats,
    @Default(0) double kcal,
  }) = _Macros;

  Macros operator +(Macros other) => Macros(
    protein: protein + other.protein,
    carbs: carbs + other.carbs,
    fats: fats + other.fats,
    kcal: kcal + other.kcal,
  );
}
