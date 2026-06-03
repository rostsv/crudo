import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/repositories/product_repository.dart';

import 'in_memory_crud.dart';

class InMemoryProductRepository extends InMemoryCrud<Product>
    implements ProductRepository {
  InMemoryProductRepository({Iterable<Product> seed = const []})
    : super((p) => p.id, seed);
}
