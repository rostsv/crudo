import 'package:freezed_annotation/freezed_annotation.dart';

import '../food/food.dart';
import '../shared/enums.dart';
import '../shared/grams.dart';

part 'food_snapshot.freezed.dart';

/// A library food fixed at a weight (instance tree) — PURE VALUE, state-free.
/// Macros + kcal are ABSOLUTES for [grams], computed once at creation; the
/// per-100g source is deliberately not carried (derivable as abs/grams×100;
/// grams edits scale linearly). `sourceFoodId` is a weak back-ref only —
/// later library edits/deletes never alter this snapshot (architecture §8).
@freezed
abstract class FoodSnapshot with _$FoodSnapshot {
  const FoodSnapshot._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  @Assert('kcal >= 0', 'kcal must be >= 0')
  const factory FoodSnapshot({
    String? sourceFoodId,
    required String name,
    @Default(FoodKind.product) FoodKind kind,
    required FoodCategory category,
    required Grams grams,
    required double protein,
    required double carbs,
    required double fats,
    required double kcal,
  }) = _FoodSnapshot;

  /// The one creation door: resolve a library food at a weight, baking the
  /// absolutes in (per-100g × grams / 100).
  factory FoodSnapshot.from(Food food, Grams grams) {
    final factor = grams.value / 100.0;
    return FoodSnapshot(
      sourceFoodId: food.id,
      name: food.name,
      kind: food.kind,
      category: food.category,
      grams: grams,
      protein: food.protein * factor,
      carbs: food.carbs * factor,
      fats: food.fats * factor,
      kcal: food.kcalPer100g * factor,
    );
  }
}
