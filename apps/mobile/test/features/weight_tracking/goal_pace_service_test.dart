import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/weight_tracking/domain/services/goal_pace_service.dart';
import 'package:mobile/features/weight_tracking/domain/services/weight_trend_service.dart';

void main() {
  group('GoalPaceService', () {
    const service = GoalPaceService();

    test('estimates target date for weight loss', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        currentWeightKg: 62.2,
        goalWeightKg: 52,
        weeklyPaceKg: 0.4,
        fromDate: DateTime(2026, 8, 16),
      );

      expect(result.remainingKg, closeTo(10.2, 0.001));

      expect(result.estimatedWeeksRemaining, closeTo(25.5, 0.001));

      expect(result.estimatedDaysRemaining, 179);

      expect(result.estimatedTargetDate, DateTime(2027, 2, 11));

      expect(result.goalReached, isFalse);

      expect(result.hasEstimate, isTrue);
    });

    test('estimates target date for weight gain', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.gain,
        currentWeightKg: 64,
        goalWeightKg: 70,
        weeklyPaceKg: 0.3,
        fromDate: DateTime(2026, 8, 16),
      );

      expect(result.remainingKg, closeTo(6, 0.001));

      expect(result.estimatedWeeksRemaining, closeTo(20, 0.001));

      expect(result.estimatedDaysRemaining, 140);

      expect(result.estimatedTargetDate, DateTime(2027, 1, 3));

      expect(result.goalReached, isFalse);
    });

    test('returns no estimate when weight-loss goal is reached', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.lose,
        currentWeightKg: 51.8,
        goalWeightKg: 52,
        weeklyPaceKg: 0.4,
        fromDate: DateTime(2026, 8, 16),
      );

      expect(result.goalReached, isTrue);

      expect(result.remainingKg, closeTo(0, 0.001));

      expect(result.estimatedWeeksRemaining, isNull);

      expect(result.estimatedDaysRemaining, isNull);

      expect(result.estimatedTargetDate, isNull);

      expect(result.hasEstimate, isFalse);
    });

    test('returns no directional estimate for maintenance goal', () {
      final result = service.calculate(
        goalDirection: WeightGoalDirection.maintain,
        currentWeightKg: 65,
        goalWeightKg: 65,
        weeklyPaceKg: null,
        fromDate: DateTime(2026, 8, 16),
      );

      expect(result.goalReached, isTrue);

      expect(result.remainingKg, closeTo(0, 0.001));

      expect(result.weeklyPaceKg, isNull);

      expect(result.estimatedTargetDate, isNull);
    });

    test(
      'reports distance from maintenance target without estimating date',
      () {
        final result = service.calculate(
          goalDirection: WeightGoalDirection.maintain,
          currentWeightKg: 66.2,
          goalWeightKg: 65,
          weeklyPaceKg: null,
          fromDate: DateTime(2026, 8, 16),
        );

        expect(result.goalReached, isFalse);

        expect(result.remainingKg, closeTo(1.2, 0.001));

        expect(result.estimatedTargetDate, isNull);

        expect(result.hasEstimate, isFalse);
      },
    );

    test('rejects zero or negative directional pace', () {
      expect(
        () => service.calculate(
          goalDirection: WeightGoalDirection.lose,
          currentWeightKg: 65,
          goalWeightKg: 52,
          weeklyPaceKg: 0,
          fromDate: DateTime(2026, 8, 16),
        ),
        throwsArgumentError,
      );

      expect(
        () => service.calculate(
          goalDirection: WeightGoalDirection.gain,
          currentWeightKg: 65,
          goalWeightKg: 70,
          weeklyPaceKg: -0.5,
          fromDate: DateTime(2026, 8, 16),
        ),
        throwsArgumentError,
      );
    });
  });
}
