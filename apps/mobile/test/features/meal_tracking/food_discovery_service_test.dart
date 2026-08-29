import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/recent_food_reference.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_preferences_repository.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_repository.dart';
import 'package:mobile/features/meal_tracking/domain/services/food_discovery_service.dart';

void main() {
  group('FoodDiscoveryService', () {
    test('sorts favorites by food name', () async {
      final banana = _food(id: 'banana', name: 'Banana');
      final apple = _food(id: 'apple', name: 'Apple');

      final preferences = FakeFoodPreferencesRepository(
        favorites: {banana.identityKey, apple.identityKey},
      );

      final service = FoodDiscoveryService(
        foodRepository: FakeFoodRepository(foods: [banana, apple]),
        preferencesRepository: preferences,
      );

      final overview = await service.loadOverview();

      expect(overview.favorites.map((food) => food.name).toList(), [
        'Apple',
        'Banana',
      ]);
    });

    test('keeps recent foods in usage order', () async {
      final banana = _food(id: 'banana', name: 'Banana');
      final apple = _food(id: 'apple', name: 'Apple');

      final preferences = FakeFoodPreferencesRepository(
        recents: [
          RecentFoodReference(
            identityKey: banana.identityKey,
            usedAt: DateTime.utc(2026, 8, 29, 12),
          ),
          RecentFoodReference(
            identityKey: apple.identityKey,
            usedAt: DateTime.utc(2026, 8, 28, 12),
          ),
        ],
      );

      final service = FoodDiscoveryService(
        foodRepository: FakeFoodRepository(foods: [apple, banana]),
        preferencesRepository: preferences,
      );

      final overview = await service.loadOverview();

      expect(overview.recents.map((food) => food.name).toList(), [
        'Banana',
        'Apple',
      ]);
    });

    test('does not duplicate favorite foods in recents', () async {
      final banana = _food(id: 'banana', name: 'Banana');

      final preferences = FakeFoodPreferencesRepository(
        favorites: {banana.identityKey},
        recents: [
          RecentFoodReference(
            identityKey: banana.identityKey,
            usedAt: DateTime.utc(2026, 8, 29, 12),
          ),
        ],
      );

      final service = FoodDiscoveryService(
        foodRepository: FakeFoodRepository(foods: [banana]),
        preferencesRepository: preferences,
      );

      final overview = await service.loadOverview();

      expect(overview.favorites.single.id, 'banana');
      expect(overview.recents, isEmpty);
    });

    test('skips persisted identities that no longer resolve', () async {
      final preferences = FakeFoodPreferencesRepository(
        favorites: {'localCatalog:prana-local:missing'},
        recents: [
          RecentFoodReference(
            identityKey: 'localCatalog:prana-local:also-missing',
            usedAt: DateTime.utc(2026, 8, 29, 12),
          ),
        ],
      );

      final service = FoodDiscoveryService(
        foodRepository: FakeFoodRepository(foods: const []),
        preferencesRepository: preferences,
      );

      final overview = await service.loadOverview();

      expect(overview.favorites, isEmpty);
      expect(overview.recents, isEmpty);
    });
  });
}

CatalogFood _food({required String id, required String name}) {
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

class FakeFoodPreferencesRepository implements FoodPreferencesRepository {
  FakeFoodPreferencesRepository({
    Set<String>? favorites,
    List<RecentFoodReference>? recents,
  }) : favorites = favorites ?? <String>{},
       recents = recents ?? <RecentFoodReference>[];

  final Set<String> favorites;
  final List<RecentFoodReference> recents;

  @override
  Future<Set<String>> loadFavoriteIdentityKeys() async {
    return {...favorites};
  }

  @override
  Future<List<RecentFoodReference>> loadRecents() async {
    return [...recents];
  }

  @override
  Future<void> recordRecent(String identityKey, {DateTime? usedAt}) async {}

  @override
  Future<void> setFavorite(
    String identityKey, {
    required bool isFavorite,
  }) async {}
}
