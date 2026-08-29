import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
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
        MaterialApp(home: FoodSearchScreen(repository: repository)),
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
        MaterialApp(home: FoodSearchScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'banana');
      await tester.pumpAndSettle();

      expect(repository.queries, contains('banana'));
    });

    testWidgets('shows a retry state when the repository throws', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FoodSearchScreen(repository: ThrowingFoodRepository()),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Prana could not search foods right now.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });
  });
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
