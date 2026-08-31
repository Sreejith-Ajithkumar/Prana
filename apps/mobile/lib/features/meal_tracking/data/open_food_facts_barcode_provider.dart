import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/barcode_lookup_result.dart';
import '../domain/entities/catalog_food.dart';
import '../domain/entities/product_barcode.dart';
import '../domain/repositories/barcode_food_provider.dart';

class OpenFoodFactsBarcodeProvider implements BarcodeFoodProvider {
  OpenFoodFactsBarcodeProvider({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
    this.userAgent = defaultUserAgent,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const String providerIdentifier = 'open-food-facts';

  /// Replace with Prana's public support URL/contact before store release.
  static const String defaultUserAgent =
      'Prana-Mobile/0.8-development (barcode lookup)';

  static const List<String> _requestedFields = [
    'code',
    'product_name',
    'generic_name',
    'brands',
    'serving_size',
    'nutriments',
  ];

  final http.Client _client;
  final bool _ownsClient;
  final Duration requestTimeout;
  final String userAgent;

  @override
  String get providerId => providerIdentifier;

  @override
  Future<BarcodeLookupResult> lookup(ProductBarcode barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v3/product/${barcode.value}',
      {'fields': _requestedFields.join(',')},
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {'Accept': 'application/json', 'User-Agent': userAgent},
          )
          .timeout(requestTimeout);

      if (response.statusCode == 404) {
        return BarcodeLookupNotFound(barcode: barcode);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return BarcodeLookupUnavailable(barcode: barcode);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        return BarcodeLookupUnavailable(barcode: barcode);
      }

      final rawProduct = decoded['product'];

      if (rawProduct is! Map<String, dynamic>) {
        return BarcodeLookupNotFound(barcode: barcode);
      }

      return _mapProduct(barcode: barcode, product: rawProduct);
    } on TimeoutException {
      return BarcodeLookupUnavailable(barcode: barcode);
    } on http.ClientException {
      return BarcodeLookupUnavailable(barcode: barcode);
    } on FormatException {
      return BarcodeLookupUnavailable(barcode: barcode);
    } on TypeError {
      return BarcodeLookupUnavailable(barcode: barcode);
    }
  }

  BarcodeLookupResult _mapProduct({
    required ProductBarcode barcode,
    required Map<String, dynamic> product,
  }) {
    final name =
        _nonEmptyString(product['product_name']) ??
        _nonEmptyString(product['generic_name']);

    if (name == null) {
      return BarcodeLookupIncomplete(barcode: barcode);
    }

    final nutriments = product['nutriments'];

    if (nutriments is! Map<String, dynamic>) {
      return BarcodeLookupIncomplete(barcode: barcode, productName: name);
    }

    final nutrition = _readNutrition(nutriments, product);

    if (nutrition == null) {
      return BarcodeLookupIncomplete(barcode: barcode, productName: name);
    }

    final serverCode = _nonEmptyString(product['code']) ?? barcode.value;
    final brand = _nonEmptyString(product['brands']);
    final genericName = _nonEmptyString(product['generic_name']);

    final searchTerms = <String>[
      if (genericName != null &&
          genericName.toLowerCase() != name.toLowerCase())
        genericName,
    ];

    final food = CatalogFood(
      id: serverCode,
      name: name,
      brand: brand,
      barcode: barcode.value,
      source: CatalogFoodSource.externalCatalog,
      providerId: providerIdentifier,
      servingDescription: nutrition.servingDescription,
      servingQuantity: nutrition.servingQuantity,
      servingUnit: nutrition.servingUnit,
      calories: nutrition.calories,
      proteinGrams: nutrition.proteinGrams,
      carbohydrateGrams: nutrition.carbohydrateGrams,
      fatGrams: nutrition.fatGrams,
      searchTerms: searchTerms,
    );

    return BarcodeLookupSuccess(barcode: barcode, food: food);
  }

  _NutritionBasis? _readNutrition(
    Map<String, dynamic> nutriments,
    Map<String, dynamic> product,
  ) {
    final servingCalories = _finiteNonNegativeNumber(
      nutriments['energy-kcal_serving'],
    );

    if (servingCalories != null) {
      return _NutritionBasis(
        servingDescription:
            _nonEmptyString(product['serving_size']) ?? '1 serving',
        servingQuantity: 1,
        servingUnit: 'serving',
        calories: servingCalories,
        proteinGrams:
            _finiteNonNegativeNumber(nutriments['proteins_serving']) ?? 0,
        carbohydrateGrams:
            _finiteNonNegativeNumber(nutriments['carbohydrates_serving']) ?? 0,
        fatGrams: _finiteNonNegativeNumber(nutriments['fat_serving']) ?? 0,
      );
    }

    final caloriesPer100Grams = _finiteNonNegativeNumber(
      nutriments['energy-kcal_100g'],
    );

    if (caloriesPer100Grams == null) {
      return null;
    }

    return _NutritionBasis(
      servingDescription: '100 g',
      servingQuantity: 100,
      servingUnit: 'g',
      calories: caloriesPer100Grams,
      proteinGrams: _finiteNonNegativeNumber(nutriments['proteins_100g']) ?? 0,
      carbohydrateGrams:
          _finiteNonNegativeNumber(nutriments['carbohydrates_100g']) ?? 0,
      fatGrams: _finiteNonNegativeNumber(nutriments['fat_100g']) ?? 0,
    );
  }

  String? _nonEmptyString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  double? _finiteNonNegativeNumber(dynamic value) {
    final parsed = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text.trim()),
      _ => null,
    };

    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return null;
    }

    return parsed;
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class _NutritionBasis {
  const _NutritionBasis({
    required this.servingDescription,
    required this.servingQuantity,
    required this.servingUnit,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final String servingDescription;
  final double servingQuantity;
  final String servingUnit;
  final double calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;
}
