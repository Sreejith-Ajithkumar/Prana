import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/data/custom_food_storage_backend.dart';
import 'package:mobile/features/meal_tracking/data/persistent_custom_food_repository.dart';
import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/custom_food_draft.dart';

void main() {
  group('PersistentCustomFoodRepository', () {
    test('creates and reloads a provider-aware custom food', () async {
      final backend = MemoryCustomFoodStorageBackend();
      final repository = PersistentCustomFoodRepository(
        storageBackend: backend,
        idFactory: () => 'custom-1',
      );

      final created = await repository.createCustomFood(
        _draft(name: 'Protein oats', brand: 'Home recipe'),
      );

      expect(created.source, CatalogFoodSource.custom);
      expect(created.providerId, 'prana-custom');
      expect(created.identityKey, 'custom:prana-custom:custom-1');

      final reloadedRepository = PersistentCustomFoodRepository(
        storageBackend: backend,
        idFactory: () => 'custom-2',
      );

      final reloaded = await reloadedRepository.findFoodByIdentity(
        created.identityKey,
      );

      expect(reloaded?.name, 'Protein oats');
      expect(reloaded?.brand, 'Home recipe');
    });

    test('searches custom food names and brands', () async {
      final repository = PersistentCustomFoodRepository(
        storageBackend: MemoryCustomFoodStorageBackend(),
        idFactory: () => 'custom-1',
      );

      await repository.createCustomFood(
        _draft(name: 'Greek yogurt bowl', brand: 'Kitchen batch'),
      );

      expect(
        (await repository.searchFoods('yogurt')).single.name,
        'Greek yogurt bowl',
      );
      expect(
        (await repository.searchFoods('kitchen')).single.name,
        'Greek yogurt bowl',
      );
    });

    test('updates a custom food without changing its identity', () async {
      final repository = PersistentCustomFoodRepository(
        storageBackend: MemoryCustomFoodStorageBackend(),
        idFactory: () => 'custom-1',
      );

      final created = await repository.createCustomFood(
        _draft(name: 'Morning oats'),
      );

      final updated = await repository.updateCustomFood(
        created.identityKey,
        _draft(name: 'Morning protein oats', calories: 420),
      );

      expect(updated.identityKey, created.identityKey);
      expect(updated.name, 'Morning protein oats');
      expect(updated.calories, 420);

      final stored = await repository.findFoodByIdentity(created.identityKey);

      expect(stored?.name, 'Morning protein oats');
    });

    test('deletes a custom food', () async {
      final repository = PersistentCustomFoodRepository(
        storageBackend: MemoryCustomFoodStorageBackend(),
        idFactory: () => 'custom-1',
      );

      final created = await repository.createCustomFood(
        _draft(name: 'Delete me'),
      );

      await repository.deleteCustomFood(created.identityKey);

      expect(await repository.findFoodByIdentity(created.identityKey), isNull);
      expect(await repository.searchFoods(''), isEmpty);
    });

    test('ignores malformed persisted records instead of crashing', () async {
      final backend = MemoryCustomFoodStorageBackend(
        initialValue: '''
[
  {"id":"broken","name":"Missing nutrition"},
  {
    "id":"custom-2",
    "name":"Valid food",
    "brand":null,
    "servingDescription":"1 serving",
    "servingQuantity":1,
    "servingUnit":"serving",
    "calories":200,
    "proteinGrams":10,
    "carbohydrateGrams":20,
    "fatGrams":5
  }
]
''',
      );

      final repository = PersistentCustomFoodRepository(
        storageBackend: backend,
      );

      final foods = await repository.searchFoods('');

      expect(foods, hasLength(1));
      expect(foods.single.name, 'Valid food');
    });
  });
}

CustomFoodDraft _draft({
  required String name,
  String? brand,
  double calories = 350,
}) {
  return CustomFoodDraft(
    name: name,
    brand: brand,
    servingQuantity: 1,
    servingUnit: 'bowl',
    calories: calories,
    proteinGrams: 20,
    carbohydrateGrams: 40,
    fatGrams: 10,
  );
}

class MemoryCustomFoodStorageBackend implements CustomFoodStorageBackend {
  MemoryCustomFoodStorageBackend({String? initialValue}) : value = initialValue;

  String? value;

  @override
  Future<String?> read() async {
    return value;
  }

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
