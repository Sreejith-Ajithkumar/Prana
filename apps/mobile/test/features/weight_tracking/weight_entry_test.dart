import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/weight_tracking/domain/entities/weight_entry.dart';

void main() {
  group('WeightEntry', () {
    test('serializes and deserializes correctly', () {
      final measuredAt = DateTime(2026, 8, 14, 7, 30);

      final entry = WeightEntry(
        id: 'weight-1',
        weightKg: 65.4,
        measuredAt: measuredAt,
        source: WeightSource.manual,
        note: 'Morning weigh-in',
      );

      final json = entry.toJson();

      final restored = WeightEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.weightKg, closeTo(65.4, 0.001));
      expect(restored.measuredAt, measuredAt);
      expect(restored.source, WeightSource.manual);
      expect(restored.note, 'Morning weigh-in');
    });

    test('uses unknown source when source is not recognized', () {
      final entry = WeightEntry.fromJson({
        'id': 'weight-2',
        'weightKg': 64.8,
        'measuredAt': DateTime(2026, 8, 14).toIso8601String(),
        'source': 'futureDevice',
        'note': null,
      });

      expect(entry.source, WeightSource.unknown);
    });

    test('copyWith updates selected fields', () {
      final original = WeightEntry(
        id: 'weight-3',
        weightKg: 65,
        measuredAt: DateTime(2026, 8, 14),
      );

      final updated = original.copyWith(
        weightKg: 64.7,
        note: 'Updated reading',
      );

      expect(updated.id, original.id);

      expect(updated.weightKg, closeTo(64.7, 0.001));

      expect(updated.measuredAt, original.measuredAt);

      expect(updated.note, 'Updated reading');
    });

    test('copyWith can clear note', () {
      final original = WeightEntry(
        id: 'weight-4',
        weightKg: 65,
        measuredAt: DateTime(2026, 8, 14),
        note: 'Morning',
      );

      final updated = original.copyWith(clearNote: true);

      expect(updated.note, isNull);
    });
  });
}
