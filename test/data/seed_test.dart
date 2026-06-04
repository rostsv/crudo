import 'package:checks/checks.dart';
import 'package:crudo/data/dto/food_dto.dart';
import 'package:crudo/data/mappers/food_mapper.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dto parses json and maps to domain (isCustom false, kind product)', () {
    final dto = FoodDto.fromJson(const {
      'id': 'seed-chicken-breast',
      'name': 'Chicken breast',
      'category': 'meat',
      'protein': 31.0,
      'carbs': 0,
      'fats': 3.6,
    });
    final food = FoodMapper.toDomain(dto);
    check(food.id).equals('seed-chicken-breast');
    check(food.category).equals(FoodCategory.meat);
    check(food.protein).equals(31.0);
    check(food.carbs).equals(0.0); // int json -> double
    check(food.isCustom).isFalse();
    check(food.kind).equals(FoodKind.product);
  });

  test('seed asset loads 63 foods with known entries', () async {
    final foods = await SeedService().loadFoods();
    check(foods.length).equals(63);
    final salmon = foods.singleWhere((f) => f.id == 'seed-salmon');
    check(salmon.protein).equals(20.0);
    check(salmon.fats).equals(13.0);
    check(salmon.category).equals(FoodCategory.fish);
    final oil = foods.singleWhere((f) => f.id == 'seed-olive-oil');
    check(oil.fats).equals(100.0);
    // every category except custom is represented
    final categories = foods.map((f) => f.category).toSet();
    check(categories.length).equals(7);
    check(categories.contains(FoodCategory.custom)).isFalse();
  });

  test('seed kcalPer100g is formula-derived and kind is product', () async {
    final foods = await SeedService().loadFoods();
    final chicken = foods.singleWhere((f) => f.id == 'seed-chicken-breast');
    check(chicken.kind).equals(FoodKind.product);
    check(
      chicken.kcalPer100g,
    ).isCloseTo(31.0 * 4 + 0.0 * 4 + 3.6 * 9, 1e-9); // 156.4
  });
}
