import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mobile/features/meal_tracking/data/global_food_search_provider.dart';

void main() {
  test(
    'maps valid products, excludes incomplete records, deduplicates codes',
    () async {
      var requests = 0;
      final provider = OpenFoodFactsGlobalSearchProvider(
        client: MockClient((request) async {
          requests++;
          expect(request.url.path, '/cgi/search.pl');
          expect(request.url.queryParameters['search_terms'], 'kimchi');
          return Response(
            jsonEncode({
              'products': [
                {
                  'code': '123',
                  'product_name': 'Kimchi',
                  'brands': 'Test',
                  'nutriments': {
                    'energy-kcal_100g': 45,
                    'proteins_100g': 2,
                    'carbohydrates_100g': 7,
                    'fat_100g': 1,
                  },
                },
                {
                  'code': '123',
                  'product_name': 'Duplicate',
                  'nutriments': {'energy-kcal_100g': 50},
                },
                {'code': '456', 'product_name': 'Incomplete'},
              ],
            }),
            200,
          );
        }),
      );
      expect(await provider.search('a'), isEmpty);
      expect(requests, 0);
      final foods = await provider.search('kimchi');
      expect(requests, 1);
      expect(foods, hasLength(1));
      expect(foods.first.name, 'Kimchi');
      expect(foods.first.calories, 45);
      expect(foods.first.servingDescription, '100 g');
      expect(foods.first.providerId, 'open-food-facts');
    },
  );

  test('keeps serving-based data as serving-based data', () async {
    final provider = OpenFoodFactsGlobalSearchProvider(
      client: MockClient(
        (_) async => Response(
          jsonEncode({
            'products': [
              {
                'code': '789',
                'product_name': 'Snack',
                'serving_size': '30 g',
                'nutriments': {
                  'energy-kcal_serving': 120,
                  'proteins_serving': 4,
                  'energy-kcal_100g': 400,
                },
              },
            ],
          }),
          200,
        ),
      ),
    );
    final food = (await provider.search('snack')).single;
    expect(food.servingDescription, '30 g');
    expect(food.servingUnit, 'serving');
    expect(food.calories, 120);
  });

  test('reports server errors for UI fallback', () async {
    final provider = OpenFoodFactsGlobalSearchProvider(
      client: MockClient((_) async => Response('busy', 503)),
    );

    expect(
      () => provider.search('cereal'),
      throwsA(
        isA<GlobalFoodSearchException>()
            .having(
              (error) => error.reason,
              'reason',
              GlobalFoodSearchFailureReason.temporarilyUnavailable,
            )
            .having((error) => error.statusCode, 'status code', 503),
      ),
    );
  });
}
