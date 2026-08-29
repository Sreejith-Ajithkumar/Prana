import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/recent_food_reference.dart';
import '../domain/repositories/food_preferences_repository.dart';

class FoodPreferencesStorage implements FoodPreferencesRepository {
  FoodPreferencesStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static final FoodPreferencesStorage instance = FoodPreferencesStorage();

  static const String _recentsKey = 'prana_recent_foods_v1';
  static const String _favoritesKey = 'prana_favorite_foods_v1';

  static const int maximumRecentFoods = 20;

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<RecentFoodReference>> loadRecents() async {
    final encoded = await _preferences.getString(_recentsKey);

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List<dynamic>) {
        return [];
      }

      final records = decoded
          .map(
            (item) =>
                RecentFoodReference.fromJson(item as Map<String, dynamic>),
          )
          .where((record) => record.identityKey.trim().isNotEmpty)
          .toList();

      records.sort((a, b) => b.usedAt.compareTo(a.usedAt));

      return records;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    } on ArgumentError {
      return [];
    }
  }

  @override
  Future<Set<String>> loadFavoriteIdentityKeys() async {
    final values = await _preferences.getStringList(_favoritesKey);

    if (values == null) {
      return <String>{};
    }

    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  @override
  Future<void> recordRecent(String identityKey, {DateTime? usedAt}) async {
    final normalizedIdentity = identityKey.trim();

    if (normalizedIdentity.isEmpty) {
      return;
    }

    final existing = await loadRecents();

    final updated = <RecentFoodReference>[
      RecentFoodReference(
        identityKey: normalizedIdentity,
        usedAt: (usedAt ?? DateTime.now()).toUtc(),
      ),
      ...existing.where((record) => record.identityKey != normalizedIdentity),
    ].take(maximumRecentFoods).toList(growable: false);

    await _preferences.setString(
      _recentsKey,
      jsonEncode(
        updated.map((record) => record.toJson()).toList(growable: false),
      ),
    );
  }

  @override
  Future<void> setFavorite(
    String identityKey, {
    required bool isFavorite,
  }) async {
    final normalizedIdentity = identityKey.trim();

    if (normalizedIdentity.isEmpty) {
      return;
    }

    final favorites = await loadFavoriteIdentityKeys();

    if (isFavorite) {
      favorites.add(normalizedIdentity);
    } else {
      favorites.remove(normalizedIdentity);
    }

    final ordered = favorites.toList()..sort();

    await _preferences.setStringList(_favoritesKey, ordered);
  }
}
