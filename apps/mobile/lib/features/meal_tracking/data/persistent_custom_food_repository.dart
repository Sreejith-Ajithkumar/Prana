import 'dart:convert';

import '../domain/entities/catalog_food.dart';
import '../domain/entities/custom_food_draft.dart';
import '../domain/repositories/custom_food_repository.dart';
import '../domain/services/food_search_ranker.dart';
import 'custom_food_storage_backend.dart';

class PersistentCustomFoodRepository implements CustomFoodRepository {
  PersistentCustomFoodRepository({
    CustomFoodStorageBackend? storageBackend,
    this.searchRanker = const FoodSearchRanker(),
    String Function()? idFactory,
  }) : _storageBackend =
           storageBackend ?? SharedPreferencesCustomFoodStorageBackend(),
       _idFactory =
           idFactory ??
           (() => 'custom-${DateTime.now().microsecondsSinceEpoch}');

  static final PersistentCustomFoodRepository instance =
      PersistentCustomFoodRepository();

  final CustomFoodStorageBackend _storageBackend;
  final FoodSearchRanker searchRanker;
  final String Function() _idFactory;

  @override
  Future<List<CatalogFood>> searchFoods(String query) async {
    final foods = await _loadFoods();

    return searchRanker.search(foods, query);
  }

  @override
  Future<CatalogFood?> findFoodById(String id) async {
    final foods = await _loadFoods();

    for (final food in foods) {
      if (food.id == id) {
        return food;
      }
    }

    return null;
  }

  @override
  Future<CatalogFood?> findFoodByIdentity(String identityKey) async {
    final foods = await _loadFoods();

    for (final food in foods) {
      if (food.identityKey == identityKey) {
        return food;
      }
    }

    return null;
  }

  @override
  Future<CatalogFood> createCustomFood(CustomFoodDraft draft) async {
    draft.validate();

    final foods = await _loadFoods();
    final food = draft.toCatalogFood(id: _idFactory());

    if (foods.any((existing) => existing.identityKey == food.identityKey)) {
      throw StateError('A custom food with this identity already exists.');
    }

    foods.add(food);
    _sortFoods(foods);

    await _saveFoods(foods);

    return food;
  }

  @override
  Future<CatalogFood> updateCustomFood(
    String identityKey,
    CustomFoodDraft draft,
  ) async {
    draft.validate();

    final foods = await _loadFoods();
    final index = foods.indexWhere((food) => food.identityKey == identityKey);

    if (index < 0) {
      throw StateError('Custom food not found.');
    }

    final existing = foods[index];

    if (existing.source != CatalogFoodSource.custom ||
        existing.providerId != 'prana-custom') {
      throw StateError('Only Prana custom foods can be edited here.');
    }

    final updated = draft.toCatalogFood(id: existing.id);

    foods[index] = updated;
    _sortFoods(foods);

    await _saveFoods(foods);

    return updated;
  }

  @override
  Future<void> deleteCustomFood(String identityKey) async {
    final foods = await _loadFoods();
    final before = foods.length;

    foods.removeWhere((food) => food.identityKey == identityKey);

    if (foods.length == before) {
      return;
    }

    await _saveFoods(foods);
  }

  Future<List<CatalogFood>> _loadFoods() async {
    final encoded = await _storageBackend.read();

    if (encoded == null || encoded.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List<dynamic>) {
        return [];
      }

      final foods = <CatalogFood>[];

      for (final item in decoded) {
        final food = _decodeFood(item);

        if (food != null) {
          foods.add(food);
        }
      }

      _sortFoods(foods);

      return foods;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    } on ArgumentError {
      return [];
    }
  }

  Future<void> _saveFoods(List<CatalogFood> foods) async {
    await _storageBackend.write(
      jsonEncode(foods.map(_encodeFood).toList(growable: false)),
    );
  }

  CatalogFood? _decodeFood(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return null;
    }

    final id = item['id'];
    final name = item['name'];
    final servingDescription = item['servingDescription'];
    final servingQuantity = item['servingQuantity'];
    final servingUnit = item['servingUnit'];
    final calories = item['calories'];
    final proteinGrams = item['proteinGrams'];
    final carbohydrateGrams = item['carbohydrateGrams'];
    final fatGrams = item['fatGrams'];

    if (id is! String ||
        name is! String ||
        servingDescription is! String ||
        servingQuantity is! num ||
        servingUnit is! String ||
        calories is! num ||
        proteinGrams is! num ||
        carbohydrateGrams is! num ||
        fatGrams is! num) {
      return null;
    }

    final brandValue = item['brand'];
    final brand = brandValue is String && brandValue.trim().isNotEmpty
        ? brandValue.trim()
        : null;

    final draft = CustomFoodDraft(
      name: name,
      brand: brand,
      servingQuantity: servingQuantity.toDouble(),
      servingUnit: servingUnit,
      calories: calories.toDouble(),
      proteinGrams: proteinGrams.toDouble(),
      carbohydrateGrams: carbohydrateGrams.toDouble(),
      fatGrams: fatGrams.toDouble(),
    );

    try {
      draft.validate();
    } on ArgumentError {
      return null;
    }

    return CatalogFood(
      id: id,
      name: name.trim(),
      brand: brand,
      servingDescription: servingDescription.trim().isEmpty
          ? draft.servingDescription
          : servingDescription.trim(),
      servingQuantity: servingQuantity.toDouble(),
      servingUnit: servingUnit.trim(),
      calories: calories.toDouble(),
      proteinGrams: proteinGrams.toDouble(),
      carbohydrateGrams: carbohydrateGrams.toDouble(),
      fatGrams: fatGrams.toDouble(),
      source: CatalogFoodSource.custom,
      providerId: 'prana-custom',
    );
  }

  Map<String, dynamic> _encodeFood(CatalogFood food) {
    return {
      'id': food.id,
      'name': food.name,
      'brand': food.brand,
      'servingDescription': food.servingDescription,
      'servingQuantity': food.servingQuantity,
      'servingUnit': food.servingUnit,
      'calories': food.calories,
      'proteinGrams': food.proteinGrams,
      'carbohydrateGrams': food.carbohydrateGrams,
      'fatGrams': food.fatGrams,
    };
  }

  void _sortFoods(List<CatalogFood> foods) {
    foods.sort((a, b) {
      final nameComparison = a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      );

      if (nameComparison != 0) {
        return nameComparison;
      }

      return a.identityKey.compareTo(b.identityKey);
    });
  }
}
