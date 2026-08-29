import '../entities/catalog_food.dart';

/// Deterministically filters and ranks foods for local/offline search.
///
/// Ranking intentionally prefers user-visible canonical names over hidden
/// aliases. This keeps search explainable while still supporting regional and
/// common-name discovery.
///
/// The same ranker can later be reused by custom-food storage or other local
/// collections without coupling them to [LocalFoodRepository].
class FoodSearchRanker {
  const FoodSearchRanker();

  List<CatalogFood> search(Iterable<CatalogFood> foods, String query) {
    final normalizedQuery = normalize(query);
    final foodList = foods.toList(growable: false);

    if (normalizedQuery.isEmpty) {
      return foodList;
    }

    final queryTokens = normalizedQuery.split(' ');

    final matches = <_RankedFood>[];

    for (final food in foodList) {
      final score = _score(
        food: food,
        query: normalizedQuery,
        queryTokens: queryTokens,
      );

      if (score != null) {
        matches.add(_RankedFood(food: food, score: score));
      }
    }

    matches.sort((a, b) {
      final scoreComparison = a.score.compareTo(b.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      final nameComparison = normalize(
        a.food.name,
      ).compareTo(normalize(b.food.name));

      if (nameComparison != 0) {
        return nameComparison;
      }

      return a.food.identityKey.compareTo(b.food.identityKey);
    });

    return matches.map((match) => match.food).toList(growable: false);
  }

  /// Produces a search-friendly representation of user/provider text.
  ///
  /// Case, punctuation, and repeated whitespace are ignored.
  String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  int? _score({
    required CatalogFood food,
    required String query,
    required List<String> queryTokens,
  }) {
    final name = normalize(food.name);
    final brand = normalize(food.brand ?? '');
    final aliases = food.searchTerms
        .map(normalize)
        .where((term) => term.isNotEmpty)
        .toList(growable: false);

    if (name == query) {
      return 0;
    }

    if (name.startsWith(query)) {
      return 10;
    }

    if (_wordStartsWith(name, query)) {
      return 20;
    }

    if (name.contains(query)) {
      return 30;
    }

    if (brand == query) {
      return 40;
    }

    if (brand.startsWith(query)) {
      return 45;
    }

    if (brand.contains(query)) {
      return 50;
    }

    if (aliases.any((alias) => alias == query)) {
      return 60;
    }

    if (aliases.any((alias) => alias.startsWith(query))) {
      return 70;
    }

    if (aliases.any((alias) => _wordStartsWith(alias, query))) {
      return 80;
    }
    final searchableWords = [name, brand, ...aliases]
        .where((value) => value.isNotEmpty)
        .expand((value) => value.split(' '))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (queryTokens.every(
      (token) => searchableWords.any((word) => word.startsWith(token)),
    )) {
      return 90;
    }

    return null;
  }

  bool _wordStartsWith(String value, String query) {
    return value.split(' ').any((word) => word.startsWith(query));
  }
}

class _RankedFood {
  const _RankedFood({required this.food, required this.score});

  final CatalogFood food;
  final int score;
}
