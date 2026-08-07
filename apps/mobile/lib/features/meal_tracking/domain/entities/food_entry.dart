class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
    required this.quantity,
    required this.unit,
  });

  final String id;
  final String name;
  final double calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;
  final double quantity;
  final String unit;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbohydrateGrams': carbohydrateGrams,
      'fatGrams': fatGrams,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      proteinGrams: (json['proteinGrams'] as num).toDouble(),
      carbohydrateGrams: (json['carbohydrateGrams'] as num).toDouble(),
      fatGrams: (json['fatGrams'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}
