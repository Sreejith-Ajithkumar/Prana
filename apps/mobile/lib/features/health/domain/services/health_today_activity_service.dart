import '../entities/health_data_type.dart';
import '../repositories/health_data_repository.dart';
import 'health_daily_activity_summary_service.dart';

enum HealthTodayActivityStatus { ready, unavailable, accessNeeded }

class HealthTodayActivityResult {
  const HealthTodayActivityResult({required this.status, this.summary});

  final HealthTodayActivityStatus status;
  final HealthDailyActivitySummary? summary;

  bool get isReady => status == HealthTodayActivityStatus.ready;
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

    final accessStatus = await _repository.getAccessStatus(activityDataTypes);

    if (accessStatus != HealthAccessStatus.granted) {
      return const HealthTodayActivityResult(
        status: HealthTodayActivityStatus.accessNeeded,
      );
    }

    final current = now ?? DateTime.now();

    final startTime = DateTime(current.year, current.month, current.day);

    final endTime = DateTime(current.year, current.month, current.day + 1);

    final stepSamples = await _repository.readStepSamples(
      startTime: startTime,
      endTime: endTime,
    );

    final activeEnergySamples = await _repository.readActiveEnergySamples(
      startTime: startTime,
      endTime: endTime,
    );

    final workoutSamples = await _repository.readWorkoutSamples(
      startTime: startTime,
      endTime: endTime,
    );

    final summary = summaryService.summarize(
      stepSamples: stepSamples,
      activeEnergySamples: activeEnergySamples,
      workoutSamples: workoutSamples,
    );

    return HealthTodayActivityResult(
      status: HealthTodayActivityStatus.ready,
      summary: summary,
    );
  }
}
