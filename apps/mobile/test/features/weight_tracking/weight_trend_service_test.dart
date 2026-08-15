import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:mobile/features/weight_tracking/domain/services/weight_trend_service.dart';

void main() {
  group('WeightTrendService', () {
    const service = WeightTrendService();

    WeightEntry entry(String id, double weightKg, DateTime measuredAt) {
      return WeightEntry(id: id, weightKg: weightKg, measuredAt: measuredAt);
    }

    test('returns no trend when there are no measurements', () {
      final result = service.calculate(
        startingWeightKg: 65,
        goalWeightKg: 52,
        entries: const [],
      );

      expect(result.latestWeightKg, isNull);
      expect(result.trendWeightKg, isNull);
      expect(result.distinctMeasurementDays, 0);
      expect(result.hasMeasurements, isFalse);
      expect(result.hasReliableTrend, isFalse);
      expect(result.changeFromStartKg, isNull);
      expect(result.distanceToGoalKg, isNull);
    });

    test('uses latest same-day measurement but does not create a trend', () {
      final result = service.calculate(
        startingWeightKg: 65,
        goalWeightKg: 52,
        entries: [
          entry('1', 64.2, DateTime(2026, 8, 14, 7)),
          entry('2', 60, DateTime(2026, 8, 14, 20)),
        ],
      );

      expect(result.latestWeightKg, closeTo(60, 0.001));

      expect(result.distinctMeasurementDays, 1);
      expect(result.trendWeightKg, isNull);
      expect(result.hasReliableTrend, isFalse);

      expect(result.changeFromStartKg, closeTo(-5, 0.001));

      expect(result.distanceToGoalKg, closeTo(8, 0.001));
    });

    test('creates trend after measurements on three different days', () {
      final result = service.calculate(
        startingWeightKg: 65,
        goalWeightKg: 52,
        entries: [
          entry('1', 65, DateTime(2026, 8, 12, 7)),
          entry('2', 64.8, DateTime(2026, 8, 12, 20)),
          entry('3', 64.6, DateTime(2026, 8, 13, 7)),
          entry('4', 64.4, DateTime(2026, 8, 14, 7)),
        ],
      );

      // The later 64.8 kg measurement represents August 12.
      //
      // Trend:
      // (64.8 + 64.6 + 64.4) / 3 = 64.6
      expect(result.trendWeightKg, closeTo(64.6, 0.001));

      expect(result.latestWeightKg, closeTo(64.4, 0.001));

      expect(result.distinctMeasurementDays, 3);
      expect(result.hasReliableTrend, isTrue);

      // Progress calculations now use the trend weight.
      expect(result.changeFromStartKg, closeTo(-0.4, 0.001));

      expect(result.distanceToGoalKg, closeTo(12.6, 0.001));
    });

    test('uses at most seven recent daily measurements for trend', () {
      final entries = <WeightEntry>[
        entry('1', 70, DateTime(2026, 8, 1)),
        entry('2', 69, DateTime(2026, 8, 2)),
        entry('3', 68, DateTime(2026, 8, 3)),
        entry('4', 67, DateTime(2026, 8, 4)),
        entry('5', 66, DateTime(2026, 8, 5)),
        entry('6', 65, DateTime(2026, 8, 6)),
        entry('7', 64, DateTime(2026, 8, 7)),
        entry('8', 63, DateTime(2026, 8, 8)),
      ];

      final result = service.calculate(
        startingWeightKg: 70,
        goalWeightKg: 60,
        entries: entries,
      );

      // Seven most recent daily measurements:
      // 69, 68, 67, 66, 65, 64, 63
      // Average = 66
      expect(result.trendWeightKg, closeTo(66, 0.001));

      expect(result.latestWeightKg, closeTo(63, 0.001));

      expect(result.changeFromStartKg, closeTo(-4, 0.001));

      expect(result.distanceToGoalKg, closeTo(6, 0.001));
    });

    test('supports weight gain goals', () {
      final result = service.calculate(
        startingWeightKg: 60,
        goalWeightKg: 70,
        entries: [
          entry('1', 61, DateTime(2026, 8, 12)),
          entry('2', 62, DateTime(2026, 8, 13)),
          entry('3', 63, DateTime(2026, 8, 14)),
        ],
      );

      expect(result.trendWeightKg, closeTo(62, 0.001));

      expect(result.changeFromStartKg, closeTo(2, 0.001));

      expect(result.distanceToGoalKg, closeTo(8, 0.001));
    });
  });
}
