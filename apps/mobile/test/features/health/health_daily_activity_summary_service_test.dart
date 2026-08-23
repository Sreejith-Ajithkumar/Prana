import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/health/domain/entities/health_activity_sample.dart';
import 'package:mobile/features/health/domain/services/health_daily_activity_summary_service.dart';

void main() {
  const service = HealthDailyActivitySummaryService();

  group('HealthDailyActivitySummaryService', () {
    test('summarizes steps active energy and workouts', () {
      final summary = service.summarize(
        stepSamples: [
          HealthStepsSample(
            externalId: 'steps-1',
            steps: 4200,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 12),
          ),
          HealthStepsSample(
            externalId: 'steps-2',
            steps: 1800,
            startTime: DateTime(2026, 8, 23, 12),
            endTime: DateTime(2026, 8, 23, 18),
          ),
        ],
        activeEnergySamples: [
          HealthActiveEnergySample(
            externalId: 'energy-1',
            kilocalories: 310.5,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 18),
          ),
        ],
        workoutSamples: [
          HealthWorkoutSample(
            externalId: 'workout-1',
            kind: HealthWorkoutKind.running,
            startTime: DateTime(2026, 8, 23, 7),
            endTime: DateTime(2026, 8, 23, 7, 45),
          ),
        ],
      );

      expect(summary.steps, 6000);
      expect(summary.activeEnergyKcal, 310.5);
      expect(summary.workoutCount, 1);
      expect(summary.workoutDuration, const Duration(minutes: 45));
      expect(summary.hasActivity, isTrue);
    });

    test('deduplicates samples by external id', () {
      final summary = service.summarize(
        stepSamples: [
          HealthStepsSample(
            externalId: 'steps-1',
            steps: 1000,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 9),
          ),
          HealthStepsSample(
            externalId: 'steps-1',
            steps: 1000,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 9),
          ),
        ],
        activeEnergySamples: const [],
        workoutSamples: const [],
      );

      expect(summary.steps, 1000);
    });

    test('ignores invalid activity samples', () {
      final summary = service.summarize(
        stepSamples: [
          HealthStepsSample(
            externalId: 'bad-steps',
            steps: -100,
            startTime: DateTime(2026, 8, 23),
            endTime: DateTime(2026, 8, 23, 1),
          ),
        ],
        activeEnergySamples: [
          HealthActiveEnergySample(
            externalId: 'bad-energy',
            kilocalories: -50,
            startTime: DateTime(2026, 8, 23),
            endTime: DateTime(2026, 8, 23, 1),
          ),
        ],
        workoutSamples: [
          HealthWorkoutSample(
            externalId: 'bad-workout',
            kind: HealthWorkoutKind.other,
            startTime: DateTime(2026, 8, 23, 10),
            endTime: DateTime(2026, 8, 23, 9),
          ),
        ],
      );

      expect(summary.steps, 0);
      expect(summary.activeEnergyKcal, 0);
      expect(summary.workoutCount, 0);
      expect(summary.workoutDuration, Duration.zero);
      expect(summary.hasActivity, isFalse);
    });

    test('returns empty summary when no activity exists', () {
      final summary = service.summarize(
        stepSamples: const [],
        activeEnergySamples: const [],
        workoutSamples: const [],
      );

      expect(summary.steps, 0);
      expect(summary.activeEnergyKcal, 0);
      expect(summary.workoutCount, 0);
      expect(summary.workoutDuration, Duration.zero);
      expect(summary.hasActivity, isFalse);
    });

    test('calculates total workout duration', () {
      final summary = service.summarize(
        stepSamples: const [],
        activeEnergySamples: const [],
        workoutSamples: [
          HealthWorkoutSample(
            externalId: 'workout-1',
            kind: HealthWorkoutKind.strengthTraining,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 8, 30),
          ),
          HealthWorkoutSample(
            externalId: 'workout-2',
            kind: HealthWorkoutKind.walking,
            startTime: DateTime(2026, 8, 23, 18),
            endTime: DateTime(2026, 8, 23, 18, 20),
          ),
        ],
      );

      expect(summary.workoutCount, 2);
      expect(summary.workoutDuration, const Duration(minutes: 50));
    });
  });
}
