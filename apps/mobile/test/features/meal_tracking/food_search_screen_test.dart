import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/custom_food_draft.dart';
import 'package:mobile/features/meal_tracking/domain/entities/recent_food_reference.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/custom_food_repository.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_preferences_repository.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_repository.dart';
import 'package:mobile/features/meal_tracking/presentation/screens/food_search_screen.dart';

void main() {
  group('FoodSearchScreen', () {
    testWidgets('renders foods from an injected repository', (tester) async {
      final repository = FakeFoodRepository(
        foods: [
          const CatalogFood(
            id: 'provider-yogurt',
            name: 'Greek yogurt',
            brand: 'Example Foods',
            source: CatalogFoodSource.externalCatalog,
            providerId: 'example-provider',
            servingDescription: '170 g',
            servingQuantity: 170,
            servingUnit: 'g',
            calories: 100,
            proteinGrams: 17,
            carbohydrateGrams: 6,
            fatGrams: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: repository,
            preferencesRepository: FakeFoodPreferencesRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Greek yogurt'), findsOneWidget);
      expect(find.text('Example Foods'), findsOneWidget);
      expect(find.text('170 g'), findsOneWidget);
      expect(find.text('100 kcal'), findsOneWidget);
    });

    testWidgets('search text is passed through the repository contract', (
      tester,
    ) async {
      final repository = FakeFoodRepository(foods: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: repository,
            preferencesRepository: FakeFoodPreferencesRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'banana');
      await tester.pumpAndSettle();

      expect(repository.queries, contains('banana'));
    });

    testWidgets('shows a retry state when the repository throws', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: const ThrowingFoodRepository(),
            preferencesRepository: FakeFoodPreferencesRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Prana could not search foods right now.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows favorites before all foods for an empty query', (
      tester,
    ) async {
      final banana = _food(id: 'banana', name: 'Banana');
      final apple = _food(id: 'apple', name: 'Apple');

      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: FakeFoodRepository(foods: [banana, apple]),
            preferencesRepository: FakeFoodPreferencesRepository(
              favorites: {banana.identityKey},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('All foods'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('shows recently used foods for an empty query', (tester) async {
      final banana = _food(id: 'banana', name: 'Banana');

      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: FakeFoodRepository(foods: [banana]),
            preferencesRepository: FakeFoodPreferencesRepository(
              recents: [
                RecentFoodReference(
                  identityKey: banana.identityKey,
                  usedAt: DateTime.utc(2026, 8, 29, 12),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recently used'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('favorite button persists the selected food', (tester) async {
      final banana = _food(id: 'banana', name: 'Banana');
      final preferences = FakeFoodPreferencesRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: FakeFoodRepository(foods: [banana]),
            preferencesRepository: preferences,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add Banana to favorites'));
      await tester.pumpAndSettle();

      expect(preferences.favorites, contains(banana.identityKey));
      expect(find.byTooltip('Remove Banana from favorites'), findsOneWidget);
    });

    testWidgets('shows the custom food creation action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: FakeFoodRepository(foods: const []),
            preferencesRepository: FakeFoodPreferencesRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Custom'), findsOneWidget);
    });

    testWidgets('custom food results expose an edit action', (tester) async {
      final customFood = const CatalogFood(
        id: 'custom-1',
        name: 'My oats',
        servingDescription: '1 bowl',
        servingQuantity: 1,
        servingUnit: 'bowl',
        calories: 350,
        proteinGrams: 20,
        carbohydrateGrams: 40,
        fatGrams: 10,
        source: CatalogFoodSource.custom,
        providerId: 'prana-custom',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FoodSearchScreen(
            repository: FakeFoodRepository(foods: [customFood]),
            preferencesRepository: FakeFoodPreferencesRepository(),
            customFoodRepository: FakeCustomFoodRepository(foods: [customFood]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit My oats'), findsOneWidget);
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
  final List<String> queries = [];

  @override
  Future<List<CatalogFood>> searchFoods(String query) async {
    queries.add(query);

    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return foods;
    }

    return foods.where((food) {
      return food.name.toLowerCase().contains(normalizedQuery);
    }).toList();
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

class FakeCustomFoodRepository extends FakeFoodRepository
    implements CustomFoodRepository {
  FakeCustomFoodRepository({required super.foods});

  @override
  Future<CatalogFood> createCustomFood(CustomFoodDraft draft) async {
    return draft.toCatalogFood(id: 'custom-created');
  }

  @override
  Future<CatalogFood> updateCustomFood(
    String identityKey,
    CustomFoodDraft draft,
  ) async {
    return draft.toCatalogFood(id: 'custom-updated');
  }

  @override
  Future<void> deleteCustomFood(String identityKey) async {}
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
  Future<void> recordRecent(String identityKey, {DateTime? usedAt}) async {
    recents.removeWhere((record) => record.identityKey == identityKey);
    recents.insert(
      0,
      RecentFoodReference(
        identityKey: identityKey,
        usedAt: usedAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setFavorite(
    String identityKey, {
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      favorites.add(identityKey);
    } else {
      favorites.remove(identityKey);
    }
  }
}

class ThrowingFoodRepository implements FoodRepository {
  const ThrowingFoodRepository();

  @override
  Future<List<CatalogFood>> searchFoods(String query) {
    throw StateError('Search failed');
  }

  @override
  Future<CatalogFood?> findFoodById(String id) {
    throw StateError('Search failed');
  }

  @override
  Future<CatalogFood?> findFoodByIdentity(String identityKey) {
    throw StateError('Search failed');
  }
}
