import '../entities/catalog_food.dart';

abstract interface class FoodRepository {
  Future<List<CatalogFood>> searchFoods(String query);

  Future<CatalogFood?> findFoodById(String id);
}
