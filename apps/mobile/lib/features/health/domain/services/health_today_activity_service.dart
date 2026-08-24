import '../entities/health_activity_sample.dart';
import '../entities/health_data_type.dart';
import '../repositories/health_data_repository.dart';
import 'health_daily_activity_summary_service.dart';

enum HealthTodayActivityStatus { ready, unavailable, accessNeeded }

class HealthTodayActivityResult {
  const HealthTodayActivityResult({
    required this.status,
    this.summary,
    this.hasStepsAccess = false,
    this.hasActiveEnergyAccess = false,
    this.hasWorkoutAccess = false,
  });

  final HealthTodayActivityStatus status;
  final HealthDailyActivitySummary? summary;

  final bool hasStepsAccess;
  final bool hasActiveEnergyAccess;
  final bool hasWorkoutAccess;

  bool get isReady => status == HealthTodayActivityStatus.ready;

  bool get hasAnyAccess =>
      hasStepsAccess || hasActiveEnergyAccess || hasWorkoutAccess;

  bool get hasFullAccess =>
      hasStepsAccess && hasActiveEnergyAccess && hasWorkoutAccess;

  bool get hasPartialAccess => hasAnyAccess && !hasFullAccess;
}

class HealthTodayActivityService {
  const HealthTodayActivityService(
    this._repository, {
    this.summaryService = const HealthDailyActivitySummaryService(),
  });

  final HealthActivityDataRepository _repository;
  final HealthDailyActivitySummaryService summaryService;

  static const Set<HealthDataType> activityDataTypes = {
    HealthDataType.steps,
    HealthDataType.activeEnergyBurned,
    HealthDataType.workout,
  };

  Future<HealthTodayActivityResult> load({DateTime? now}) async {
    final availability = await _repository.checkAvailability();

    if (!availability.isAvailable) {
      return const HealthTodayActivityResult(
        status: HealthTodayActivityStatus.unavailable,
      );
    }

    final stepsAccess = await _repository.getAccessStatus(const {
      HealthDataType.steps,
    });

    final activeEnergyAccess = await _repository.getAccessStatus(const {
      HealthDataType.activeEnergyBurned,
    });

    final workoutAccess = await _repository.getAccessStatus(const {
      HealthDataType.workout,
    });

    final hasStepsAccess = _isGranted(stepsAccess);
    final hasActiveEnergyAccess = _isGranted(activeEnergyAccess);
    final hasWorkoutAccess = _isGranted(workoutAccess);

    final hasAnyAccess =
        hasStepsAccess || hasActiveEnergyAccess || hasWorkoutAccess;

    if (!hasAnyAccess) {
      return HealthTodayActivityResult(
        status: HealthTodayActivityStatus.accessNeeded,
        hasStepsAccess: hasStepsAccess,
        hasActiveEnergyAccess: hasActiveEnergyAccess,
        hasWorkoutAccess: hasWorkoutAccess,
      );
    }

    final current = now ?? DateTime.now();

    final startTime = DateTime(current.year, current.month, current.day);

    final endTime = DateTime(current.year, current.month, current.day + 1);

    final stepSamples = hasStepsAccess
        ? await _repository.readStepSamples(
            startTime: startTime,
            endTime: endTime,
          )
        : const <HealthStepsSample>[];

    final activeEnergySamples = hasActiveEnergyAccess
        ? await _repository.readActiveEnergySamples(
            startTime: startTime,
            endTime: endTime,
          )
        : const <HealthActiveEnergySample>[];

    final workoutSamples = hasWorkoutAccess
        ? await _repository.readWorkoutSamples(
            startTime: startTime,
            endTime: endTime,
          )
        : const <HealthWorkoutSample>[];

    final summary = summaryService.summarize(
      stepSamples: stepSamples,
      activeEnergySamples: activeEnergySamples,
      workoutSamples: workoutSamples,
    );

    return HealthTodayActivityResult(
      status: HealthTodayActivityStatus.ready,
      summary: summary,
      hasStepsAccess: hasStepsAccess,
      hasActiveEnergyAccess: hasActiveEnergyAccess,
      hasWorkoutAccess: hasWorkoutAccess,
    );
  }

  bool _isGranted(HealthAccessStatus status) {
    return status == HealthAccessStatus.granted;
  }
}
