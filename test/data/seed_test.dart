import 'package:checks/checks.dart';
import 'package:crudo/data/dto/product_dto.dart';
import 'package:crudo/data/mappers/product_mapper.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dto parses json and maps to domain (isCustom false)', () {
    final dto = ProductDto.fromJson(const {
      'id': 'seed-chicken-breast',
      'name': 'Chicken breast',
      'category': 'meat',
      'protein': 31.0,
      'carbs': 0,
      'fats': 3.6,
    });
    final product = ProductMapper.toDomain(dto);
    check(product.id).equals('seed-chicken-breast');
    check(product.category).equals(ProductCategory.meat);
    check(product.protein).equals(31.0);
    check(product.carbs).equals(0.0); // int json -> double
    check(product.isCustom).isFalse();
    check(product.kcalOverride).isNull();
  });

  test('seed asset loads 63 products with known entries', () async {
    final products = await SeedService().loadProducts();
    check(products.length).equals(63);
    final salmon = products.singleWhere((p) => p.id == 'seed-salmon');
    check(salmon.protein).equals(20.0);
    check(salmon.fats).equals(13.0);
    check(salmon.category).equals(ProductCategory.fish);
    final oil = products.singleWhere((p) => p.id == 'seed-olive-oil');
    check(oil.fats).equals(100.0);
    // every category except custom is represented
    final categories = products.map((p) => p.category).toSet();
    check(categories.length).equals(7);
    check(categories.contains(ProductCategory.custom)).isFalse();
  });
}
