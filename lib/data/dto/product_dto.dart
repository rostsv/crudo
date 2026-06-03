/// Wire shape of a seed product (assets/seed/products.json). Hand-written —
/// no JSON codegen in the project until S20 justifies it.
class ProductDto {
  const ProductDto({
    required this.id,
    required this.name,
    required this.category,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) => ProductDto(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fats: (json['fats'] as num).toDouble(),
  );

  final String id;
  final String name;
  final String category;
  final double protein;
  final double carbs;
  final double fats;
}
