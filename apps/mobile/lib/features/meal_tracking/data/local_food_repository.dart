import '../domain/entities/catalog_food.dart';
import '../domain/repositories/food_repository.dart';

class LocalFoodRepository implements FoodRepository {
  const LocalFoodRepository();

  static const List<CatalogFood> _foods = [
    CatalogFood(
      id: 'black-tea',
      name: 'Black tea, unsweetened',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 2,
      proteinGrams: 0,
      carbohydrateGrams: 0.5,
      fatGrams: 0,
    ),
    CatalogFood(
      id: 'tea-milk-sugar',
      name: 'Tea with milk and sugar',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 90,
      proteinGrams: 2,
      carbohydrateGrams: 15,
      fatGrams: 2.5,
    ),
    CatalogFood(
      id: 'masala-chai',
      name: 'Masala chai',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 120,
      proteinGrams: 3,
      carbohydrateGrams: 20,
      fatGrams: 3,
    ),
    CatalogFood(
      id: 'boiled-egg',
      name: 'Boiled egg',
      servingDescription: '1 large egg',
      servingQuantity: 1,
      servingUnit: 'egg',
      calories: 78,
      proteinGrams: 6.3,
      carbohydrateGrams: 0.6,
      fatGrams: 5.3,
    ),
    CatalogFood(
      id: 'banana',
      name: 'Banana',
      servingDescription: '1 medium banana',
      servingQuantity: 1,
      servingUnit: 'banana',
      calories: 105,
      proteinGrams: 1.3,
      carbohydrateGrams: 27,
      fatGrams: 0.4,
    ),
    CatalogFood(
      id: 'apple',
      name: 'Apple',
      servingDescription: '1 medium apple',
      servingQuantity: 1,
      servingUnit: 'apple',
      calories: 95,
      proteinGrams: 0.5,
      carbohydrateGrams: 25,
      fatGrams: 0.3,
    ),
    CatalogFood(
      id: 'white-rice',
      name: 'Cooked white rice',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 205,
      proteinGrams: 4.3,
      carbohydrateGrams: 44.5,
      fatGrams: 0.4,
    ),
    CatalogFood(
      id: 'chicken-breast',
      name: 'Cooked chicken breast',
      servingDescription: '100 g',
      servingQuantity: 100,
      servingUnit: 'g',
      calories: 165,
      proteinGrams: 31,
      carbohydrateGrams: 0,
      fatGrams: 3.6,
    ),
    CatalogFood(
      id: 'chicken-wings',
      name: 'Cooked chicken wings',
      servingDescription: '100 g',
      servingQuantity: 100,
      servingUnit: 'g',
      calories: 203,
      proteinGrams: 30.5,
      carbohydrateGrams: 0,
      fatGrams: 8.1,
    ),
    CatalogFood(
      id: 'whole-milk',
      name: 'Whole milk',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 149,
      proteinGrams: 7.7,
      carbohydrateGrams: 11.7,
      fatGrams: 7.9,
    ),
    CatalogFood(
      id: 'plain-yogurt',
      name: 'Plain yogurt',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 149,
      proteinGrams: 8.5,
      carbohydrateGrams: 11.4,
      fatGrams: 8,
    ),
    CatalogFood(
      id: 'oatmeal',
      name: 'Cooked oatmeal',
      servingDescription: '1 cup',
      servingQuantity: 1,
      servingUnit: 'cup',
      calories: 154,
      proteinGrams: 6,
      carbohydrateGrams: 27,
      fatGrams: 2.6,
    ),
  ];

  @override
  Future<List<CatalogFood>> searchFoods(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return _foods;
    }

    return _foods.where((food) {
      return food.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<CatalogFood?> findFoodById(String id) async {
    for (final food in _foods) {
      if (food.id == id) {
        return food;
      }
    }

    return null;
  }
}
