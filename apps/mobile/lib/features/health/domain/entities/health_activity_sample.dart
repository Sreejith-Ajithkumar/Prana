enum HealthWorkoutKind {
  walking,
  running,
  cycling,
  swimming,
  strengthTraining,
  other,
}

class HealthStepsSample {
  const HealthStepsSample({
    required this.externalId,
    required this.steps,
    required this.startTime,
    required this.endTime,
    this.sourceName,
  });

  final String externalId;
  final int steps;
  final DateTime startTime;
  final DateTime endTime;
  final String? sourceName;
}

class HealthActiveEnergySample {
  const HealthActiveEnergySample({
    required this.externalId,
    required this.kilocalories,
    required this.startTime,
    required this.endTime,
    this.sourceName,
  });

  final String externalId;
  final double kilocalories;
  final DateTime startTime;
  final DateTime endTime;
  final String? sourceName;
}

class HealthWorkoutSample {
  const HealthWorkoutSample({
    required this.externalId,
    required this.kind,
    required this.startTime,
    required this.endTime,
    this.sourceName,
  });

  final String externalId;
  final HealthWorkoutKind kind;
  final DateTime startTime;
  final DateTime endTime;
  final String? sourceName;

  Duration get duration => endTime.difference(startTime);
}
