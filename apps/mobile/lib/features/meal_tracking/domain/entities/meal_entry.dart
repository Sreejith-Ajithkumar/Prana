import '../enums/meal_type.dart';
import 'food_entry.dart';

class MealEntry {
  const MealEntry({
    required this.id,
    required this.type,
    required this.loggedAt,
    required this.foods,
  });

  final String id;
  final MealType type;
  final DateTime loggedAt;
  final List<FoodEntry> foods;

  double get calories {
    return foods.fold(0, (total, food) => total + food.calories);
  }

  double get proteinGrams {
    return foods.fold(0, (total, food) => total + food.proteinGrams);
  }

  double get carbohydrateGrams {
    return foods.fold(0, (total, food) => total + food.carbohydrateGrams);
  }

  double get fatGrams {
    return foods.fold(0, (total, food) => total + food.fatGrams);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'loggedAt': loggedAt.toIso8601String(),
      'foods': foods.map((food) => food.toJson()).toList(),
    };
  }

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    final foodsJson = json['foods'] as List<dynamic>;

    return MealEntry(
      id: json['id'] as String,
      type: MealType.values.byName(json['type'] as String),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      foods: foodsJson
          .map((item) => FoodEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
