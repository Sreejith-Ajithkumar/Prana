import '../domain/repositories/food_repository.dart';
import 'composite_food_repository.dart';
import 'local_food_repository.dart';

/// Creates the repository used by Prana's food discovery UI.
///
/// New providers can be added here without coupling presentation code to
/// provider-specific implementations.
FoodRepository createFoodRepository() {
  return const CompositeFoodRepository(repositories: [LocalFoodRepository()]);
}
