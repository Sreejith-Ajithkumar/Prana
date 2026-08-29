import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/services/food_search_ranker.dart';

void main() {
  group('FoodSearchRanker', () {
    const ranker = FoodSearchRanker();

    test('empty query preserves source order', () {
      final foods = [
        _food(id: 'b', name: 'Banana'),
        _food(id: 'a', name: 'Apple'),
      ];

      final results = ranker.search(foods, '   ');

      expect(results.map((food) => food.id).toList(), ['b', 'a']);
    });
    test('does not match query inside the middle of a word', () {
      final results = ranker.search([
        _food(
          id: 'rice',
          name: 'Cooked white rice',
          searchTerms: const ['steamed rice'],
        ),
      ], 'tea');

      expect(results, isEmpty);
    });

    test('normalizes punctuation, case, and repeated whitespace', () {
      final results = ranker.search([
        _food(id: 'tea', name: 'Tea with milk and sugar'),
      ], '  TEA---WITH   MILK  ');

      expect(results.single.id, 'tea');
    });

    test('ranks exact name before prefix and contains matches', () {
      final results = ranker.search([
        _food(id: 'contains', name: 'Cooked apple slices'),
        _food(id: 'prefix', name: 'Apple pie'),
        _food(id: 'exact', name: 'Apple'),
      ], 'apple');

      expect(results.map((food) => food.id).toList(), [
        'exact',
        'prefix',
        'contains',
      ]);
    });

    test('canonical name outranks a hidden alias', () {
      final results = ranker.search([
        _food(id: 'alias', name: 'Tea with milk', searchTerms: const ['chai']),
        _food(id: 'canonical', name: 'Masala chai'),
      ], 'chai');

      expect(results.map((food) => food.id).toList(), ['canonical', 'alias']);
    });

    test('searches brand names', () {
      final results = ranker.search([
        _food(id: 'branded', name: 'Greek yogurt', brand: 'Example Foods'),
        _food(id: 'other', name: 'Plain yogurt'),
      ], 'example');

      expect(results.single.id, 'branded');
    });

    test('supports multi-token fallback across searchable fields', () {
      final results = ranker.search([
        _food(
          id: 'match',
          name: 'Greek yogurt',
          brand: 'Example Foods',
          searchTerms: const ['high protein'],
        ),
        _food(id: 'miss', name: 'Plain yogurt'),
      ], 'example protein');

      expect(results.single.id, 'match');
    });
  });
}

CatalogFood _food({
  required String id,
  required String name,
  String? brand,
  List<String> searchTerms = const [],
}) {
  return CatalogFood(
    id: id,
    name: name,
    brand: brand,
    searchTerms: searchTerms,
    servingDescription: '1 serving',
    servingQuantity: 1,
    servingUnit: 'serving',
    calories: 100,
    proteinGrams: 5,
    carbohydrateGrams: 10,
    fatGrams: 4,
  );
}
