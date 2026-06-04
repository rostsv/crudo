import 'dart:convert';

import 'package:crudo/domain/food/food.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../dto/food_dto.dart';
import '../mappers/food_mapper.dart';

/// Loads the bundled food seed (the initial catalog cache — a server-side
/// catalog with periodic refresh replaces the source at S20+, same contract).
class SeedService {
  Future<List<Food>> loadFoods() async {
    final raw = await rootBundle.loadString('assets/seed/products.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(FoodDto.fromJson).map(FoodMapper.toDomain).toList();
  }
}
