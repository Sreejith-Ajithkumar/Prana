import '../entities/catalog_food.dart';
import '../repositories/food_preferences_repository.dart';
import '../repositories/food_repository.dart';

class FoodDiscoveryOverview {
  const FoodDiscoveryOverview({
    required this.favorites,
    required this.recents,
    required this.favoriteIdentityKeys,
  });

  final List<CatalogFood> favorites;
  final List<CatalogFood> recents;
  final Set<String> favoriteIdentityKeys;
}

/// Resolves persisted favorite/recent identities back into current catalog
/// records.
///
/// Favorites are sorted by canonical food name. Recents keep usage order and
/// exclude foods already shown in Favorites so the empty-search experience
/// does not duplicate the same food across both priority sections.
class FoodDiscoveryService {
  const FoodDiscoveryService({
    required this.foodRepository,
    required this.preferencesRepository,
  });

  final FoodRepository foodRepository;
  final FoodPreferencesRepository preferencesRepository;

  Future<FoodDiscoveryOverview> loadOverview() async {
    final favoriteIdentityKeys = await preferencesRepository
        .loadFavoriteIdentityKeys();

    final recentReferences = await preferencesRepository.loadRecents();

    final favorites = await _resolveFoods(favoriteIdentityKeys);

    favorites.sort((a, b) {
      final nameComparison = a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      );

      if (nameComparison != 0) {
        return nameComparison;
      }

      return a.identityKey.compareTo(b.identityKey);
    });

    final recents = <CatalogFood>[];

    for (final reference in recentReferences) {
      if (favoriteIdentityKeys.contains(reference.identityKey)) {
        continue;
      }

      final food = await foodRepository.findFoodByIdentity(
        reference.identityKey,
      );

      if (food != null) {
        recents.add(food);
      }
    }

    return FoodDiscoveryOverview(
      favorites: favorites,
      recents: recents,
      favoriteIdentityKeys: Set.unmodifiable(favoriteIdentityKeys),
    );
  }

  Future<List<CatalogFood>> _resolveFoods(Iterable<String> identities) async {
    final foods = <CatalogFood>[];

    for (final identity in identities) {
      final food = await foodRepository.findFoodByIdentity(identity);

      if (food != null) {
        foods.add(food);
      }
    }

    return foods;
  }
}
