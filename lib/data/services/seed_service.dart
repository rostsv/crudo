import 'dart:convert';

import 'package:crudo/domain/product/product.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../dto/product_dto.dart';
import '../mappers/product_mapper.dart';

/// Loads the bundled product seed (the initial catalog cache — a server-side
/// catalog with periodic refresh replaces the source at S20+, same contract).
class SeedService {
  Future<List<Product>> loadProducts() async {
    final raw = await rootBundle.loadString('assets/seed/products.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(ProductDto.fromJson).map(ProductMapper.toDomain).toList();
  }
}
