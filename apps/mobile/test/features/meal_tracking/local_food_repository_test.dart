import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/data/local_food_repository.dart';
import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';

void main() {
  group('LocalFoodRepository', () {
    const repository = LocalFoodRepository();

    test('returns the built-in catalog for an empty query', () async {
      final results = await repository.searchFoods('');

      expect(results, hasLength(12));
      expect(
        results.every((food) => food.source == CatalogFoodSource.localCatalog),
        isTrue,
      );
      expect(results.every((food) => food.providerId == 'prana-local'), isTrue);
    });

    test('search is trimmed and case insensitive', () async {
      final results = await repository.searchFoods('  CHICKEN  ');

      expect(
        results.map((food) => food.id),
        containsAll(['chicken-breast', 'chicken-wings']),
      );
      expect(results, hasLength(2));
    });

    test('findFoodById returns a matching food', () async {
      final food = await repository.findFoodById('banana');

      expect(food, isNotNull);
      expect(food!.name, 'Banana');
    });

    test('findFoodByIdentity uses provider-aware identity', () async {
      final food = await repository.findFoodById('banana');

      final resolved = await repository.findFoodByIdentity(food!.identityKey);

      expect(resolved?.id, 'banana');
    });

    test('unknown identity returns null', () async {
      final food = await repository.findFoodByIdentity(
        'externalCatalog:unknown:banana',
      );

      expect(food, isNull);
    });
  });
}
