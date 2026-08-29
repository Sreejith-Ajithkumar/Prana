import '../entities/catalog_food.dart';

/// Search/read contract for a source of food catalog records.
///
/// Presentation code depends on this interface rather than on a specific
/// local or remote food provider.
abstract interface class FoodRepository {
  Future<List<CatalogFood>> searchFoods(String query);

  /// Finds the first food with the provider-native [id].
  ///
  /// This method remains useful for a single repository. Code that already
  /// has a provider-aware identity should prefer [findFoodByIdentity].
  Future<CatalogFood?> findFoodById(String id);

  /// Finds a food using [CatalogFood.identityKey].
  Future<CatalogFood?> findFoodByIdentity(String identityKey);
}
