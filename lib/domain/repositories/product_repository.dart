import '../product/product.dart';

/// Single source of truth for products (seed + user-created).
/// Contract notes: [watchAll] emits the current list immediately on listen,
/// then again after every mutation. [delete] removes the product from all
/// queries; already-materialized day snapshots are unaffected (detached).
abstract class ProductRepository {
  Stream<List<Product>> watchAll();
  Future<List<Product>> getAll();
  Future<Product?> getById(String id);
  Future<void> save(Product product);
  Future<void> delete(String id);
}
