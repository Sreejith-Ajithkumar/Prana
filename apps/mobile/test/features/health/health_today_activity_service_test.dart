import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/health/domain/entities/health_activity_sample.dart';
import 'package:mobile/features/health/domain/entities/health_data_type.dart';
import 'package:mobile/features/health/domain/repositories/health_data_repository.dart';
import 'package:mobile/features/health/domain/services/health_today_activity_service.dart';

void main() {
  group('HealthTodayActivityService', () {
    test('returns unavailable when health platform is unavailable', () async {
      final repository = FakeHealthActivityDataRepository(
        availability: const HealthAvailability(
          platform: HealthPlatform.healthConnect,
          isAvailable: false,
        ),
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.unavailable);

      expect(result.summary, isNull);
      expect(repository.readCount, 0);
    });

    test('returns access needed when access is denied', () async {
      final repository = FakeHealthActivityDataRepository(
        accessStatus: HealthAccessStatus.denied,
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.accessNeeded);

      expect(result.summary, isNull);
      expect(repository.readCount, 0);
    });

    test('returns access needed when access is partial', () async {
      final repository = FakeHealthActivityDataRepository(
        accessStatus: HealthAccessStatus.partiallyGranted,
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.accessNeeded);

      expect(result.summary, isNull);
      expect(repository.readCount, 0);
    });

    test('reads and summarizes today activity', () async {
      final repository = FakeHealthActivityDataRepository(
        stepSamples: [
          HealthStepsSample(
            externalId: 'steps-1',
            steps: 7200,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 17),
          ),
        ],
        activeEnergySamples: [
          HealthActiveEnergySample(
            externalId: 'energy-1',
            kilocalories: 412.5,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 17),
          ),
        ],
        workoutSamples: [
          HealthWorkoutSample(
            externalId: 'workout-1',
            kind: HealthWorkoutKind.running,
            startTime: DateTime(2026, 8, 23, 7),
            endTime: DateTime(2026, 8, 23, 7, 40),
          ),
        ],
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.ready);

      expect(result.isReady, isTrue);
      expect(result.summary, isNotNull);
      expect(result.summary!.steps, 7200);
      expect(result.summary!.activeEnergyKcal, 412.5);
      expect(result.summary!.workoutCount, 1);
      expect(result.summary!.workoutDuration, const Duration(minutes: 40));

      expect(repository.readCount, 3);
    });

    test('uses local calendar day as read range', () async {
      final repository = FakeHealthActivityDataRepository();

      final service = HealthTodayActivityService(repository);

      await service.load(now: DateTime(2026, 8, 23, 23, 45));

      expect(repository.lastStartTime, DateTime(2026, 8, 23));

      expect(repository.lastEndTime, DateTime(2026, 8, 24));
    });
  });
}

class FakeHealthActivityDataRepository implements HealthActivityDataRepository {
  FakeHealthActivityDataRepository({
    this.availability = const HealthAvailability(
      platform: HealthPlatform.healthConnect,
      isAvailable: true,
    ),
    this.accessStatus = HealthAccessStatus.granted,
    this.stepSamples = const [],
    this.activeEnergySamples = const [],
    this.workoutSamples = const [],
  });

  final HealthAvailability availability;
  final HealthAccessStatus accessStatus;

  final List<HealthStepsSample> stepSamples;
  final List<HealthActiveEnergySample> activeEnergySamples;
  final List<HealthWorkoutSample> workoutSamples;

  int readCount = 0;

  DateTime? lastStartTime;
  DateTime? lastEndTime;

  @override
  Future<HealthAvailability> checkAvailability() async {
    return availability;
  }

  @override
  Future<HealthAccessStatus> getAccessStatus(
    Set<HealthDataType> dataTypes,
  ) async {
    return accessStatus;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    return accessStatus;
  }

  @override
  Future<void> openHealthSettings() async {}

  @override
  Future<List<HealthStepsSample>> readStepSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _recordRead(startTime, endTime);

    return stepSamples;
  }

  @override
  Future<List<HealthActiveEnergySample>> readActiveEnergySamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _recordRead(startTime, endTime);

    return activeEnergySamples;
  }

  @override
  Future<List<HealthWorkoutSample>> readWorkoutSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _recordRead(startTime, endTime);

    return workoutSamples;
  }

  void _recordRead(DateTime startTime, DateTime endTime) {
    readCount++;
    lastStartTime = startTime;
    lastEndTime = endTime;
  }
}
