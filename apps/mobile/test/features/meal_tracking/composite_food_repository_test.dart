import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/data/composite_food_repository.dart';
import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_repository.dart';

void main() {
  group('CompositeFoodRepository', () {
    test('merges provider results in repository priority order', () async {
      final localFood = _food(id: 'rice', name: 'Local rice');

      final externalFood = _food(
        id: 'yogurt',
        name: 'External yogurt',
        source: CatalogFoodSource.externalCatalog,
        providerId: 'example-provider',
      );

      final repository = CompositeFoodRepository(
        repositories: [
          FakeFoodRepository(foods: [localFood]),
          FakeFoodRepository(foods: [externalFood]),
        ],
      );

      final results = await repository.searchFoods('');

      expect(results.map((food) => food.name).toList(), [
        'Local rice',
        'External yogurt',
      ]);
    });

    test('deduplicates the same provider-aware identity', () async {
      final food = _food(id: 'banana', name: 'Banana');

      final repository = CompositeFoodRepository(
        repositories: [
          FakeFoodRepository(foods: [food]),
          FakeFoodRepository(foods: [food]),
        ],
      );

      final results = await repository.searchFoods('');

      expect(results, hasLength(1));
    });

    test('keeps matching raw ids from different providers distinct', () async {
      final localFood = _food(id: 'banana', name: 'Local banana');

      final externalFood = _food(
        id: 'banana',
        name: 'External banana',
        source: CatalogFoodSource.externalCatalog,
        providerId: 'external-provider',
      );

      final repository = CompositeFoodRepository(
        repositories: [
          FakeFoodRepository(foods: [localFood]),
          FakeFoodRepository(foods: [externalFood]),
        ],
      );

      final results = await repository.searchFoods('');

      expect(results, hasLength(2));
      expect(results[0].identityKey, isNot(results[1].identityKey));
    });

    test('one failing provider does not block available providers', () async {
      final availableFood = _food(id: 'egg', name: 'Egg');

      final repository = CompositeFoodRepository(
        repositories: [
          const ThrowingFoodRepository(),
          FakeFoodRepository(foods: [availableFood]),
        ],
      );

      final results = await repository.searchFoods('');

      expect(results.map((food) => food.name), ['Egg']);
    });

    test('findFoodByIdentity resolves the exact provider food', () async {
      final localFood = _food(id: 'rice', name: 'Local rice');

      final externalFood = _food(
        id: 'rice',
        name: 'External rice',
        source: CatalogFoodSource.externalCatalog,
        providerId: 'external-provider',
      );

      final repository = CompositeFoodRepository(
        repositories: [
          FakeFoodRepository(foods: [localFood]),
          FakeFoodRepository(foods: [externalFood]),
        ],
      );

      final resolved = await repository.findFoodByIdentity(
        externalFood.identityKey,
      );

      expect(resolved?.name, 'External rice');
    });
  });
}

CatalogFood _food({
  required String id,
  required String name,
  CatalogFoodSource source = CatalogFoodSource.localCatalog,
  String providerId = 'prana-local',
}) {
  return CatalogFood(
    id: id,
    name: name,
    servingDescription: '1 serving',
    servingQuantity: 1,
    servingUnit: 'serving',
    calories: 100,
    proteinGrams: 5,
    carbohydrateGrams: 10,
    fatGrams: 4,
    source: source,
    providerId: providerId,
  );
}

class FakeFoodRepository implements FoodRepository {
  FakeFoodRepository({required this.foods});

  final List<CatalogFood> foods;

  @override
  Future<List<CatalogFood>> searchFoods(String query) async {
    return foods;
  }

  @override
  Future<CatalogFood?> findFoodById(String id) async {
    for (final food in foods) {
      if (food.id == id) {
        return food;
      }
    }

    return null;
  }

  @override
  Future<CatalogFood?> findFoodByIdentity(String identityKey) async {
    for (final food in foods) {
      if (food.identityKey == identityKey) {
        return food;
      }
    }

    return null;
  }
}

class ThrowingFoodRepository implements FoodRepository {
  const ThrowingFoodRepository();

  @override
  Future<List<CatalogFood>> searchFoods(String query) {
    throw StateError('Provider unavailable');
  }

  @override
  Future<CatalogFood?> findFoodById(String id) {
    throw StateError('Provider unavailable');
  }

  @override
  Future<CatalogFood?> findFoodByIdentity(String identityKey) {
    throw StateError('Provider unavailable');
  }
}
