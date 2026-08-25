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
      expect(result.platform, HealthPlatform.healthConnect);
      expect(result.summary, isNull);
      expect(result.hasAnyAccess, isFalse);
      expect(repository.permissionCheckCount, 0);
      expect(repository.readCount, 0);
    });

    test('returns access needed when no activity access is granted', () async {
      final repository = FakeHealthActivityDataRepository(
        accessByType: const {
          HealthDataType.steps: HealthAccessStatus.denied,
          HealthDataType.activeEnergyBurned: HealthAccessStatus.denied,
          HealthDataType.workout: HealthAccessStatus.denied,
        },
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.accessNeeded);
      expect(result.platform, HealthPlatform.healthConnect);
      expect(result.summary, isNull);
      expect(result.hasAnyAccess, isFalse);
      expect(result.hasFullAccess, isFalse);
      expect(result.hasPartialAccess, isFalse);
      expect(repository.permissionCheckCount, 3);
      expect(repository.readCount, 0);
    });

    test(
      'keeps steps available when other activity access is denied',
      () async {
        final repository = FakeHealthActivityDataRepository(
          accessByType: const {
            HealthDataType.steps: HealthAccessStatus.granted,
            HealthDataType.activeEnergyBurned: HealthAccessStatus.denied,
            HealthDataType.workout: HealthAccessStatus.denied,
          },
          stepSamples: [
            HealthStepsSample(
              externalId: 'steps-1',
              steps: 6400,
              startTime: DateTime(2026, 8, 23, 8),
              endTime: DateTime(2026, 8, 23, 17),
            ),
          ],
        );

        final service = HealthTodayActivityService(repository);

        final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

        expect(result.status, HealthTodayActivityStatus.ready);
        expect(result.platform, HealthPlatform.healthConnect);
        expect(result.summary, isNotNull);
        expect(result.summary!.steps, 6400);
        expect(result.summary!.activeEnergyKcal, 0);
        expect(result.summary!.workoutCount, 0);

        expect(result.hasStepsAccess, isTrue);
        expect(result.hasActiveEnergyAccess, isFalse);
        expect(result.hasWorkoutAccess, isFalse);
        expect(result.hasPartialAccess, isTrue);
        expect(result.hasFullAccess, isFalse);

        expect(repository.stepReadCount, 1);
        expect(repository.activeEnergyReadCount, 0);
        expect(repository.workoutReadCount, 0);
      },
    );

    test('keeps active energy available when other access is denied', () async {
      final repository = FakeHealthActivityDataRepository(
        accessByType: const {
          HealthDataType.steps: HealthAccessStatus.denied,
          HealthDataType.activeEnergyBurned: HealthAccessStatus.granted,
          HealthDataType.workout: HealthAccessStatus.denied,
        },
        activeEnergySamples: [
          HealthActiveEnergySample(
            externalId: 'energy-1',
            kilocalories: 315.5,
            startTime: DateTime(2026, 8, 23, 8),
            endTime: DateTime(2026, 8, 23, 17),
          ),
        ],
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.ready);
      expect(result.summary, isNotNull);
      expect(result.summary!.steps, 0);
      expect(result.summary!.activeEnergyKcal, 315.5);
      expect(result.summary!.workoutCount, 0);

      expect(result.hasStepsAccess, isFalse);
      expect(result.hasActiveEnergyAccess, isTrue);
      expect(result.hasWorkoutAccess, isFalse);
      expect(result.hasPartialAccess, isTrue);

      expect(repository.stepReadCount, 0);
      expect(repository.activeEnergyReadCount, 1);
      expect(repository.workoutReadCount, 0);
    });

    test('reads and summarizes all granted activity data', () async {
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
      expect(result.platform, HealthPlatform.healthConnect);
      expect(result.summary, isNotNull);
      expect(result.summary!.steps, 7200);
      expect(result.summary!.activeEnergyKcal, 412.5);
      expect(result.summary!.workoutCount, 1);
      expect(result.summary!.workoutDuration, const Duration(minutes: 40));

      expect(result.hasFullAccess, isTrue);
      expect(result.hasPartialAccess, isFalse);
      expect(repository.permissionCheckCount, 3);
      expect(repository.readCount, 3);
    });

    test('treats singleton partial permission status as not granted', () async {
      final repository = FakeHealthActivityDataRepository(
        accessByType: const {
          HealthDataType.steps: HealthAccessStatus.partiallyGranted,
          HealthDataType.activeEnergyBurned: HealthAccessStatus.denied,
          HealthDataType.workout: HealthAccessStatus.denied,
        },
      );

      final service = HealthTodayActivityService(repository);

      final result = await service.load(now: DateTime(2026, 8, 23, 15, 30));

      expect(result.status, HealthTodayActivityStatus.accessNeeded);
      expect(result.hasStepsAccess, isFalse);
      expect(repository.readCount, 0);
    });

    test('uses local calendar day as read range', () async {
      final repository = FakeHealthActivityDataRepository();

      final service = HealthTodayActivityService(repository);

      await service.load(now: DateTime(2026, 8, 23, 23, 45));

      expect(repository.lastStartTime, DateTime(2026, 8, 23));

      expect(repository.lastEndTime, DateTime(2026, 8, 24));
    });

    test(
      'attempts Apple Health reads after authorization is reviewed',
      () async {
        final repository = FakeHealthActivityDataRepository(
          availability: const HealthAvailability(
            platform: HealthPlatform.appleHealth,
            isAvailable: true,
          ),
          accessByType: const {
            HealthDataType.steps: HealthAccessStatus.unknown,
            HealthDataType.activeEnergyBurned: HealthAccessStatus.unknown,
            HealthDataType.workout: HealthAccessStatus.unknown,
          },
          stepSamples: [
            HealthStepsSample(
              externalId: 'apple-steps',
              steps: 5100,
              startTime: DateTime(2026, 8, 23, 8),
              endTime: DateTime(2026, 8, 23, 17),
            ),
          ],
        );

        final service = HealthTodayActivityService(repository);

        final result = await service.load(now: DateTime(2026, 8, 23, 18));

        expect(result.status, HealthTodayActivityStatus.ready);
        expect(result.platform, HealthPlatform.appleHealth);
        expect(result.usesPrivateReadAuthorizationSemantics, isTrue);
        expect(result.summary!.steps, 5100);
        expect(result.hasFullAccess, isTrue);
        expect(repository.readCount, 3);
      },
    );

    test(
      'does not read Apple Health before authorization is requested',
      () async {
        final repository = FakeHealthActivityDataRepository(
          availability: const HealthAvailability(
            platform: HealthPlatform.appleHealth,
            isAvailable: true,
          ),
          accessByType: const {
            HealthDataType.steps: HealthAccessStatus.notRequested,
            HealthDataType.activeEnergyBurned: HealthAccessStatus.notRequested,
            HealthDataType.workout: HealthAccessStatus.notRequested,
          },
        );

        final service = HealthTodayActivityService(repository);

        final result = await service.load(now: DateTime(2026, 8, 23, 18));

        expect(result.status, HealthTodayActivityStatus.accessNeeded);
        expect(result.platform, HealthPlatform.appleHealth);
        expect(result.hasAnyAccess, isFalse);
        expect(repository.readCount, 0);
      },
    );
  });
}

class FakeHealthActivityDataRepository implements HealthActivityDataRepository {
  FakeHealthActivityDataRepository({
    this.availability = const HealthAvailability(
      platform: HealthPlatform.healthConnect,
      isAvailable: true,
    ),
    this.accessByType = const {
      HealthDataType.steps: HealthAccessStatus.granted,
      HealthDataType.activeEnergyBurned: HealthAccessStatus.granted,
      HealthDataType.workout: HealthAccessStatus.granted,
    },
    this.stepSamples = const [],
    this.activeEnergySamples = const [],
    this.workoutSamples = const [],
  });

  final HealthAvailability availability;
  final Map<HealthDataType, HealthAccessStatus> accessByType;

  final List<HealthStepsSample> stepSamples;
  final List<HealthActiveEnergySample> activeEnergySamples;
  final List<HealthWorkoutSample> workoutSamples;

  int permissionCheckCount = 0;
  int stepReadCount = 0;
  int activeEnergyReadCount = 0;
  int workoutReadCount = 0;

  int get readCount => stepReadCount + activeEnergyReadCount + workoutReadCount;

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
    permissionCheckCount++;

    if (dataTypes.isEmpty) {
      return HealthAccessStatus.granted;
    }

    final statuses = dataTypes
        .map((type) => accessByType[type] ?? HealthAccessStatus.denied)
        .toList(growable: false);

    final grantedCount = statuses
        .where((status) => status == HealthAccessStatus.granted)
        .length;

    if (grantedCount == statuses.length) {
      return HealthAccessStatus.granted;
    }

    if (grantedCount > 0) {
      return HealthAccessStatus.partiallyGranted;
    }

    if (statuses.any((status) => status == HealthAccessStatus.unavailable)) {
      return HealthAccessStatus.unavailable;
    }

    return statuses.first;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    return getAccessStatus(dataTypes);
  }

  @override
  Future<void> openHealthSettings() async {}

  @override
  Future<List<HealthStepsSample>> readStepSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    stepReadCount++;
    _recordRange(startTime, endTime);

    return stepSamples;
  }

  @override
  Future<List<HealthActiveEnergySample>> readActiveEnergySamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    activeEnergyReadCount++;
    _recordRange(startTime, endTime);

    return activeEnergySamples;
  }

  @override
  Future<List<HealthWorkoutSample>> readWorkoutSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    workoutReadCount++;
    _recordRange(startTime, endTime);

    return workoutSamples;
  }

  void _recordRange(DateTime startTime, DateTime endTime) {
    lastStartTime = startTime;
    lastEndTime = endTime;
  }
}
