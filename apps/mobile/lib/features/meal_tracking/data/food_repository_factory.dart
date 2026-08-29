import '../domain/repositories/food_repository.dart';
import 'composite_food_repository.dart';
import 'local_food_repository.dart';
import 'persistent_custom_food_repository.dart';

/// Creates the repository used by Prana's food discovery UI.
///
/// User-created foods are intentionally placed before the built-in catalog so
/// a person's own exact foods remain easy to rediscover. New providers can be
/// added here without coupling presentation code to provider-specific
/// implementations.
FoodRepository createFoodRepository() {
  return CompositeFoodRepository(
    repositories: [
      PersistentCustomFoodRepository.instance,
      const LocalFoodRepository(),
    ],
  );
}
