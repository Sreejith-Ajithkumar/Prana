import '../entities/catalog_food.dart';
import '../entities/custom_food_draft.dart';
import 'food_repository.dart';

abstract interface class CustomFoodRepository implements FoodRepository {
  Future<CatalogFood> createCustomFood(CustomFoodDraft draft);

  Future<CatalogFood> updateCustomFood(
    String identityKey,
    CustomFoodDraft draft,
  );

  Future<void> deleteCustomFood(String identityKey);
}
