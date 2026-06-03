import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/shared/enums.dart';

import '../dto/product_dto.dart';

/// DTO -> domain. Seed products are never custom and carry no kcal override.
abstract final class ProductMapper {
  static Product toDomain(ProductDto dto) => Product(
    id: dto.id,
    name: dto.name,
    category: ProductCategory.values.byName(dto.category),
    protein: dto.protein,
    carbs: dto.carbs,
    fats: dto.fats,
  );
}
