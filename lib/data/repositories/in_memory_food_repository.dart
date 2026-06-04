import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/repositories/food_repository.dart';

import 'in_memory_crud.dart';

class InMemoryFoodRepository extends InMemoryCrud<Food>
    implements FoodRepository {
  InMemoryFoodRepository({Iterable<Food> seed = const []})
    : super((f) => f.id, seed);
}
