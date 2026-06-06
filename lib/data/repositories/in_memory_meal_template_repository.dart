import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/repositories/meal_template_repository.dart';

import 'in_memory_crud.dart';

class InMemoryMealTemplateRepository extends InMemoryCrud<MealTemplate>
    implements MealTemplateRepository {
  InMemoryMealTemplateRepository({Iterable<MealTemplate> seed = const []})
    : super((t) => t.id, seed);
}
