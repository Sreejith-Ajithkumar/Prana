import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'package:mobile/features/meal_tracking/data/open_food_facts_barcode_provider.dart';
import 'package:mobile/features/meal_tracking/domain/entities/barcode_lookup_result.dart';
import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/product_barcode.dart';

void main() {
  group('OpenFoodFactsBarcodeProvider', () {
    const barcode = ProductBarcode(
      value: '3017620422003',
      format: ProductBarcodeFormat.ean13,
    );

    test('maps a serving-based product into CatalogFood', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v3/product/3017620422003');
          expect(
            request.headers['User-Agent'],
            OpenFoodFactsBarcodeProvider.defaultUserAgent,
          );
          expect(request.url.queryParameters['fields'], contains('nutriments'));

          return Response(
            jsonEncode({
              'product': {
                'code': '3017620422003',
                'product_name': 'Hazelnut spread',
                'brands': 'Example Brand',
                'serving_size': '15 g',
                'nutriments': {
                  'energy-kcal_serving': 80,
                  'proteins_serving': 1,
                  'carbohydrates_serving': 8.6,
                  'fat_serving': 4.6,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final result = await provider.lookup(barcode);

      expect(result, isA<BarcodeLookupSuccess>());

      final food = (result as BarcodeLookupSuccess).food;

      expect(food.name, 'Hazelnut spread');
      expect(food.brand, 'Example Brand');
      expect(food.source, CatalogFoodSource.externalCatalog);
      expect(food.providerId, 'open-food-facts');
      expect(food.barcode, barcode.value);
      expect(food.servingDescription, '15 g');
      expect(food.servingQuantity, 1);
      expect(food.servingUnit, 'serving');
      expect(food.calories, 80);
      expect(food.proteinGrams, 1);
      expect(food.carbohydrateGrams, 8.6);
      expect(food.fatGrams, 4.6);
    });

    test('falls back to nutrition per 100 grams', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async {
          return Response(
            jsonEncode({
              'product': {
                'code': barcode.value,
                'product_name': 'Test crackers',
                'nutriments': {
                  'energy-kcal_100g': '420',
                  'proteins_100g': '9',
                  'carbohydrates_100g': '70',
                  'fat_100g': '11',
                },
              },
            }),
            200,
          );
        }),
      );

      final result = await provider.lookup(barcode);
      final food = (result as BarcodeLookupSuccess).food;

      expect(food.servingDescription, '100 g');
      expect(food.servingQuantity, 100);
      expect(food.servingUnit, 'g');
      expect(food.calories, 420);
    });

    test('returns not found for a 404 response', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async => Response('', 404)),
      );

      final result = await provider.lookup(barcode);

      expect(result, isA<BarcodeLookupNotFound>());
    });

    test('returns incomplete when the product has no usable name', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async {
          return Response(
            jsonEncode({
              'product': {
                'nutriments': {'energy-kcal_100g': 100},
              },
            }),
            200,
          );
        }),
      );

      final result = await provider.lookup(barcode);

      expect(result, isA<BarcodeLookupIncomplete>());
      expect((result as BarcodeLookupIncomplete).productName, isNull);
    });

    test('returns incomplete when calorie data is absent', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async {
          return Response(
            jsonEncode({
              'product': {
                'product_name': 'Incomplete cereal',
                'nutriments': {'proteins_100g': 8},
              },
            }),
            200,
          );
        }),
      );

      final result = await provider.lookup(barcode);

      expect(result, isA<BarcodeLookupIncomplete>());
      expect(
        (result as BarcodeLookupIncomplete).productName,
        'Incomplete cereal',
      );
    });

    test('returns unavailable for server errors', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async => Response('Unavailable', 503)),
      );

      final result = await provider.lookup(barcode);

      expect(result, isA<BarcodeLookupUnavailable>());
    });

    test('returns unavailable for malformed json', () async {
      final provider = OpenFoodFactsBarcodeProvider(
        client: MockClient((request) async => Response('{broken', 200)),
      );

      final result = await provider.lookup(barcode);

      expect(result, isA<BarcodeLookupUnavailable>());
    });
  });
}
