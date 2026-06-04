import '../food/food.dart';

/// Food library: seed + user customs; deleted items excluded from queries.
abstract class FoodRepository {
  Stream<List<Food>> watchAll();
  Future<List<Food>> getAll();
  Future<Food?> getById(String id);
  Future<void> save(Food food);
  Future<void> delete(String id);
}
