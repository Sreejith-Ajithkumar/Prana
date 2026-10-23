import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/meal_tracking/data/global_food_search_provider.dart';

void main() {
  test('503 is an outage, not an empty result; no automatic retries', () async {
    var requests = 0;
    final provider = OpenFoodFactsGlobalSearchProvider(
      client: MockClient((request) async {
        requests++;
        return http.Response('<html>Unavailable</html>', 503);
      }),
    );

    await expectLater(
      provider.search('coca cola'),
      throwsA(
        isA<GlobalFoodSearchException>()
            .having(
              (e) => e.reason,
              'reason',
              GlobalFoodSearchFailureReason.temporarilyUnavailable,
            )
            .having((e) => e.statusCode, 'statusCode', 503),
      ),
    );
    expect(requests, 1);
  });

  test('429 is categorized as rate limited', () async {
    final provider = OpenFoodFactsGlobalSearchProvider(
      client: MockClient((_) async => http.Response('slow down', 429)),
    );
    await expectLater(
      provider.search('yogurt'),
      throwsA(
        isA<GlobalFoodSearchException>().having(
          (e) => e.reason,
          'reason',
          GlobalFoodSearchFailureReason.rateLimited,
        ),
      ),
    );
  });

  test('200 HTML is categorized as invalid response', () async {
    final provider = OpenFoodFactsGlobalSearchProvider(
      client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
    );
    await expectLater(
      provider.search('yogurt'),
      throwsA(
        isA<GlobalFoodSearchException>().having(
          (e) => e.reason,
          'reason',
          GlobalFoodSearchFailureReason.invalidResponse,
        ),
      ),
    );
  });

  test('timeout is classified', () async {
    final provider = OpenFoodFactsGlobalSearchProvider(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      provider.search('yogurt'),
      throwsA(
        isA<GlobalFoodSearchException>().having(
          (e) => e.reason,
          'reason',
          GlobalFoodSearchFailureReason.timeout,
        ),
      ),
    );
  });
}
