import '../domain/entities/catalog_food.dart';
import '../domain/repositories/food_repository.dart';

/// Combines multiple food repositories behind one search/read contract.
///
/// Repository order defines result priority. A failure in one provider does
/// not prevent available providers from returning results.
class CompositeFoodRepository implements FoodRepository {
  const CompositeFoodRepository({required this.repositories});

  final List<FoodRepository> repositories;

  @override
  Future<List<CatalogFood>> searchFoods(String query) async {
    final resultGroups = await Future.wait(
      repositories.map((repository) => _safeSearch(repository, query)),
    );

    final seenIdentityKeys = <String>{};
    final results = <CatalogFood>[];

    for (final group in resultGroups) {
      for (final food in group) {
        if (seenIdentityKeys.add(food.identityKey)) {
          results.add(food);
        }
      }
    }

    return results;
  }

  @override
  Future<CatalogFood?> findFoodById(String id) async {
    for (final repository in repositories) {
      try {
        final food = await repository.findFoodById(id);

        if (food != null) {
          return food;
        }
      } catch (_) {
        // Continue to the next provider so one unavailable source does not
        // make the entire food catalog unavailable.
      }
    }

    return null;
  }

  @override
  Future<CatalogFood?> findFoodByIdentity(String identityKey) async {
    for (final repository in repositories) {
      try {
        final food = await repository.findFoodByIdentity(identityKey);

        if (food != null) {
          return food;
        }
      } catch (_) {
        // Continue to the next provider.
      }
    }

    return null;
  }

  static Future<List<CatalogFood>> _safeSearch(
    FoodRepository repository,
    String query,
  ) async {
    try {
      return await repository.searchFoods(query);
    } catch (_) {
      return const [];
    }
  }
}
