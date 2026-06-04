import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';

import '../dto/food_dto.dart';

/// DTO -> domain. Seed foods are never custom, all kind `product`, and carry
/// no explicit kcal — kcalPer100g defaults to the Atwater formula here
/// (the same input-time rule the S07 form applies).
abstract final class FoodMapper {
  static Food toDomain(FoodDto dto) => Food(
    id: dto.id,
    name: dto.name,
    category: FoodCategory.values.byName(dto.category),
    protein: dto.protein,
    carbs: dto.carbs,
    fats: dto.fats,
    kcalPer100g: calculatedKcal(
      protein: dto.protein,
      carbs: dto.carbs,
      fats: dto.fats,
    ),
  );
}
