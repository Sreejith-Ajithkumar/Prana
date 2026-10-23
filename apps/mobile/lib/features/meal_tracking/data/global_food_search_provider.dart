import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/entities/catalog_food.dart';

abstract class GlobalFoodSearchProvider {
  Future<List<CatalogFood>> search(String query);
  void close();
}

enum GlobalFoodSearchFailureReason {
  temporarilyUnavailable,
  rateLimited,
  connection,
  timeout,
  invalidResponse,
  httpError,
}

class GlobalFoodSearchException implements Exception {
  const GlobalFoodSearchException(this.reason, {this.statusCode});

  final GlobalFoodSearchFailureReason reason;
  final int? statusCode;

  @override
  String toString() =>
      'GlobalFoodSearchException($reason, statusCode: $statusCode)';
}

/// Submit-only worldwide search. Open Food Facts discourages autocomplete.
/// A 503 from its legacy full-text endpoint is surfaced as an outage rather
/// than mistaken for an empty result. We intentionally do not auto-retry it.
class OpenFoodFactsGlobalSearchProvider implements GlobalFoodSearchProvider {
  OpenFoodFactsGlobalSearchProvider({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.userAgent = 'Prana-Mobile/0.8-development (global food search)',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final String userAgent;

  @override
  Future<List<CatalogFood>> search(String query) async {
    final text = query.trim();
    if (text.length < 2) return const [];

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': text,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': 'code,product_name,brands,serving_size,nutriments',
    });

    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {'Accept': 'application/json', 'User-Agent': userAgent},
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.timeout,
      );
    } on http.ClientException {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.connection,
      );
    } on SocketException {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.connection,
      );
    }

    if (response.statusCode == 429) {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.rateLimited,
        statusCode: 429,
      );
    }
    if (response.statusCode == 503 || response.statusCode >= 500) {
      throw GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.temporarilyUnavailable,
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != 200) {
      throw GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.httpError,
        statusCode: response.statusCode,
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.invalidResponse,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.invalidResponse,
      );
    }
    final products = decoded['products'];
    if (products is! List) {
      throw const GlobalFoodSearchException(
        GlobalFoodSearchFailureReason.invalidResponse,
      );
    }

    final foods = <CatalogFood>[];
    final usedCodes = <String>{};
    for (final raw in products) {
      if (raw is! Map<String, dynamic>) continue;
      final food = _toFood(raw);
      if (food != null && usedCodes.add(food.id)) foods.add(food);
    }
    return foods;
  }

  CatalogFood? _toFood(Map<String, dynamic> product) {
    final code = _string(product['code']);
    final name = _string(product['product_name']);
    final nutrients = product['nutriments'];
    if (code == null || name == null || nutrients is! Map) return null;

    final perServing = _number(nutrients['energy-kcal_serving']);
    final per100 = _number(nutrients['energy-kcal_100g']);
    if (perServing == null && per100 == null) return null;
    final serving = perServing != null;
    final suffix = serving ? '_serving' : '_100g';
    final amount = _string(product['serving_size']);
    return CatalogFood(
      id: code,
      name: name,
      brand: _string(product['brands']),
      barcode: code,
      providerId: 'open-food-facts',
      source: CatalogFoodSource.externalCatalog,
      servingDescription: serving ? (amount ?? '1 serving') : '100 g',
      servingQuantity: serving ? 1 : 100,
      servingUnit: serving ? 'serving' : 'g',
      calories: perServing ?? per100!,
      proteinGrams: _number(nutrients['proteins$suffix']) ?? 0,
      carbohydrateGrams: _number(nutrients['carbohydrates$suffix']) ?? 0,
      fatGrams: _number(nutrients['fat$suffix']) ?? 0,
    );
  }

  String? _string(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  double? _number(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value.trim())
        : null;
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
