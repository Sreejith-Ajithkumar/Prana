import '../entities/health_activity_sample.dart';

class HealthDailyActivitySummary {
  const HealthDailyActivitySummary({
    required this.steps,
    required this.activeEnergyKcal,
    required this.workoutCount,
    required this.workoutDuration,
  });

  final int steps;
  final double activeEnergyKcal;
  final int workoutCount;
  final Duration workoutDuration;

  bool get hasActivity => steps > 0 || activeEnergyKcal > 0 || workoutCount > 0;
}

class HealthDailyActivitySummaryService {
  const HealthDailyActivitySummaryService();

  HealthDailyActivitySummary summarize({
    required List<HealthStepsSample> stepSamples,
    required List<HealthActiveEnergySample> activeEnergySamples,
    required List<HealthWorkoutSample> workoutSamples,
  }) {
    final uniqueSteps = <String, HealthStepsSample>{};

    for (final sample in stepSamples) {
      final id = sample.externalId.trim();

      if (id.isEmpty || sample.steps < 0) {
        continue;
      }

      uniqueSteps[id] = sample;
    }

    final uniqueEnergy = <String, HealthActiveEnergySample>{};

    for (final sample in activeEnergySamples) {
      final id = sample.externalId.trim();

      if (id.isEmpty ||
          !sample.kilocalories.isFinite ||
          sample.kilocalories < 0) {
        continue;
      }

      uniqueEnergy[id] = sample;
    }

    final uniqueWorkouts = <String, HealthWorkoutSample>{};

    for (final sample in workoutSamples) {
      final id = sample.externalId.trim();

      if (id.isEmpty || !sample.startTime.isBefore(sample.endTime)) {
        continue;
      }

      uniqueWorkouts[id] = sample;
    }

    final steps = uniqueSteps.values.fold<int>(
      0,
      (total, sample) => total + sample.steps,
    );

    final activeEnergyKcal = uniqueEnergy.values.fold<double>(
      0,
      (total, sample) => total + sample.kilocalories,
    );

    final workoutDuration = uniqueWorkouts.values.fold<Duration>(
      Duration.zero,
      (total, sample) => total + sample.duration,
    );

    return HealthDailyActivitySummary(
      steps: steps,
      activeEnergyKcal: activeEnergyKcal,
      workoutCount: uniqueWorkouts.length,
      workoutDuration: workoutDuration,
    );
  }
}
