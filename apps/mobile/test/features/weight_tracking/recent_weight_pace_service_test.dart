import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:mobile/features/weight_tracking/domain/services/recent_weight_pace_service.dart';
import 'package:mobile/features/weight_tracking/domain/services/weight_trend_service.dart';

void main() {
  group('RecentWeightPaceService', () {
    const service = RecentWeightPaceService();

    WeightEntry entry(String id, double weightKg, DateTime measuredAt) {
      return WeightEntry(id: id, weightKg: weightKg, measuredAt: measuredAt);
    }

    test('requires enough elapsed time before reporting pace', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        plannedPaceKgPerWeek: 0.4,
        entries: [
          entry('1', 65, DateTime(2026, 8, 14)),
          entry('2', 64.8, DateTime(2026, 8, 15)),
          entry('3', 64.6, DateTime(2026, 8, 16)),
        ],
      );

      expect(result.status, PaceComparisonStatus.insufficientData);

      expect(result.distinctMeasurementDays, 3);

      expect(result.measurementSpanDays, 2);

      expect(result.hasReliablePace, isFalse);

      expect(result.goalDirectedPaceKgPerWeek, isNull);
    });

    test('calculates weight-loss pace close to plan', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        plannedPaceKgPerWeek: 0.4,
        entries: [
          entry('1', 65, DateTime(2026, 8, 1)),
          entry('2', 64.6, DateTime(2026, 8, 8)),
          entry('3', 64.2, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.actualWeightChangeKgPerWeek, closeTo(-0.4, 0.001));

      expect(result.goalDirectedPaceKgPerWeek, closeTo(0.4, 0.001));

      expect(result.status, PaceComparisonStatus.closeToPlan);

      expect(result.measurementSpanDays, 14);
    });

    test('calculates weight-gain pace close to plan', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.gain,
        plannedPaceKgPerWeek: 0.3,
        entries: [
          entry('1', 60, DateTime(2026, 8, 1)),
          entry('2', 60.3, DateTime(2026, 8, 8)),
          entry('3', 60.6, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.actualWeightChangeKgPerWeek, closeTo(0.3, 0.001));

      expect(result.goalDirectedPaceKgPerWeek, closeTo(0.3, 0.001));

      expect(result.status, PaceComparisonStatus.closeToPlan);
    });

    test('detects movement away from weight-loss goal', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        plannedPaceKgPerWeek: 0.4,
        entries: [
          entry('1', 65, DateTime(2026, 8, 1)),
          entry('2', 65.2, DateTime(2026, 8, 8)),
          entry('3', 65.4, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.actualWeightChangeKgPerWeek, closeTo(0.2, 0.001));

      expect(result.goalDirectedPaceKgPerWeek, closeTo(-0.2, 0.001));

      expect(result.status, PaceComparisonStatus.movingAwayFromGoal);
    });

    test('detects slower pace than planned', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        plannedPaceKgPerWeek: 0.5,
        entries: [
          entry('1', 65, DateTime(2026, 8, 1)),
          entry('2', 64.7, DateTime(2026, 8, 8)),
          entry('3', 64.4, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.goalDirectedPaceKgPerWeek, closeTo(0.3, 0.001));

      expect(result.status, PaceComparisonStatus.slowerThanPlan);
    });

    test('detects faster pace than planned', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        plannedPaceKgPerWeek: 0.3,
        entries: [
          entry('1', 65, DateTime(2026, 8, 1)),
          entry('2', 64.5, DateTime(2026, 8, 8)),
          entry('3', 64, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.goalDirectedPaceKgPerWeek, closeTo(0.5, 0.001));

      expect(result.status, PaceComparisonStatus.fasterThanPlan);
    });

    test('uses latest measurement when multiple entries exist on same day', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        plannedPaceKgPerWeek: 0.4,
        entries: [
          entry('1', 70, DateTime(2026, 8, 1, 7)),
          entry('2', 65, DateTime(2026, 8, 1, 20)),
          entry('3', 64.6, DateTime(2026, 8, 8)),
          entry('4', 64.2, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.distinctMeasurementDays, 3);

      expect(result.goalDirectedPaceKgPerWeek, closeTo(0.4, 0.001));

      expect(result.status, PaceComparisonStatus.closeToPlan);
    });

    test('maintenance goal has no planned pace comparison', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.maintain,
        plannedPaceKgPerWeek: null,
        entries: [
          entry('1', 65, DateTime(2026, 8, 1)),
          entry('2', 65.1, DateTime(2026, 8, 8)),
          entry('3', 65.2, DateTime(2026, 8, 15)),
        ],
      );

      expect(result.hasReliablePace, isTrue);

      expect(result.actualWeightChangeKgPerWeek, closeTo(0.1, 0.001));

      expect(result.goalDirectedPaceKgPerWeek, isNull);

      expect(result.status, PaceComparisonStatus.notApplicable);
    });
  });
}
