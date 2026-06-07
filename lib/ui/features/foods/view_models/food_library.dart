import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_library.g.dart';

/// One rendered section of the library list.
typedef FoodGroup = ({String label, List<Food> foods});

/// Display labels (library sections + S07 form chips; prototype CAT_LABELS).
const foodCategoryLabels = <FoodCategory, String>{
  FoodCategory.meat: 'Meat',
  FoodCategory.fish: 'Fish',
  FoodCategory.eggs: 'Eggs & Dairy',
  FoodCategory.grain: 'Grains',
  FoodCategory.veg: 'Vegetables',
  FoodCategory.fruit: 'Fruits',
  FoodCategory.oil: 'Oils & Fats',
  FoodCategory.custom: 'Custom',
};

const dishesGroupLabel = 'Dishes';

@riverpod
Stream<List<Food>> libraryFoods(Ref ref) =>
    ref.watch(foodRepositoryProvider).watchAll();

@riverpod
class FoodSearchQuery extends _$FoodSearchQuery {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

/// Search + grouping over the whole library (S07): kind == dish → "Dishes"
/// group placed last (S05 §1.4); products grouped by category in enum
/// order; alphabetical within a group; empty groups omitted.
@riverpod
Future<List<FoodGroup>> foodLibrary(Ref ref) async {
  final foods = await ref.watch(libraryFoodsProvider.future);
  final q = ref.watch(foodSearchQueryProvider).trim().toLowerCase();
  final visible = q.isEmpty
      ? foods
      : [
          for (final f in foods)
            if (f.name.toLowerCase().contains(q)) f,
        ];
  int byName(Food a, Food b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  final groups = <FoodGroup>[];
  for (final cat in FoodCategory.values) {
    final inCat = [
      for (final f in visible)
        if (f.kind == FoodKind.product && f.category == cat) f,
    ]..sort(byName);
    if (inCat.isNotEmpty) {
      groups.add((label: foodCategoryLabels[cat]!, foods: inCat));
    }
  }
  final dishes = [
    for (final f in visible)
      if (f.kind == FoodKind.dish) f,
  ]..sort(byName);
  if (dishes.isNotEmpty) groups.add((label: dishesGroupLabel, foods: dishes));
  return groups;
}
