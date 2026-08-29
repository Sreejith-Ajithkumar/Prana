import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/recent_food_reference.dart';

void main() {
  group('RecentFoodReference', () {
    test('round trips through json in UTC', () {
      final reference = RecentFoodReference(
        identityKey: 'localCatalog:prana-local:banana',
        usedAt: DateTime.parse('2026-08-29T08:30:00-04:00'),
      );

      final decoded = RecentFoodReference.fromJson(reference.toJson());

      expect(decoded.identityKey, 'localCatalog:prana-local:banana');
      expect(decoded.usedAt, DateTime.parse('2026-08-29T12:30:00Z'));
      expect(decoded.usedAt.isUtc, isTrue);
    });
  });
}
