import '../entities/recent_food_reference.dart';

/// Persistent user preferences around food discovery.
///
/// Recent foods are recorded only after a catalog food is actually logged in
/// a meal. Merely opening or selecting a search result does not make it recent.
abstract interface class FoodPreferencesRepository {
  Future<List<RecentFoodReference>> loadRecents();

  Future<Set<String>> loadFavoriteIdentityKeys();

  Future<void> recordRecent(String identityKey, {DateTime? usedAt});

  Future<void> setFavorite(String identityKey, {required bool isFavorite});
}
