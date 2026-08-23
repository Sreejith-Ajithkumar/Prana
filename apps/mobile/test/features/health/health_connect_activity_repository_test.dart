import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health_plugin;

import 'package:mobile/features/health/data/clients/health_plugin_client.dart';
import 'package:mobile/features/health/data/permissions/activity_recognition_permission.dart';
import 'package:mobile/features/health/data/repositories/health_connect_data_repository.dart';
import 'package:mobile/features/health/data/settings/health_settings_launcher.dart';
import 'package:mobile/features/health/domain/entities/health_activity_sample.dart';

void main() {
  group('HealthConnectDataRepository activity reads', () {
    test('maps step records', () async {
      final client = FakeHealthPluginClient(
        dataPoints: [
          _numericPoint(
            uuid: 'steps-1',
            type: health_plugin.HealthDataType.STEPS,
            unit: health_plugin.HealthDataUnit.COUNT,
            value: 4321,
          ),
        ],
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final samples = await repository.readStepSamples(
        startTime: DateTime(2026, 8, 23),
        endTime: DateTime(2026, 8, 24),
      );

      expect(samples, hasLength(1));
      expect(samples.single.externalId, 'steps-1');
      expect(samples.single.steps, 4321);
      expect(samples.single.sourceName, 'Test Health');
    });

    test('maps active energy records', () async {
      final client = FakeHealthPluginClient(
        dataPoints: [
          _numericPoint(
            uuid: 'energy-1',
            type: health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,
            unit: health_plugin.HealthDataUnit.KILOCALORIE,
            value: 287.5,
          ),
        ],
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final samples = await repository.readActiveEnergySamples(
        startTime: DateTime(2026, 8, 23),
        endTime: DateTime(2026, 8, 24),
      );

      expect(samples, hasLength(1));
      expect(samples.single.externalId, 'energy-1');
      expect(samples.single.kilocalories, 287.5);
    });

    test('maps common workout categories', () async {
      final client = FakeHealthPluginClient(
        dataPoints: [
          _workoutPoint(
            uuid: 'run-1',
            type: health_plugin.HealthWorkoutActivityType.RUNNING,
          ),
          _workoutPoint(
            uuid: 'strength-1',
            type: health_plugin.HealthWorkoutActivityType.STRENGTH_TRAINING,
          ),
          _workoutPoint(
            uuid: 'swim-1',
            type: health_plugin.HealthWorkoutActivityType.SWIMMING_POOL,
          ),
          _workoutPoint(
            uuid: 'other-1',
            type: health_plugin.HealthWorkoutActivityType.YOGA,
          ),
        ],
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final samples = await repository.readWorkoutSamples(
        startTime: DateTime(2026, 8, 23),
        endTime: DateTime(2026, 8, 24),
      );

      expect(samples, hasLength(4));

      expect(samples[0].kind, HealthWorkoutKind.running);

      expect(samples[1].kind, HealthWorkoutKind.strengthTraining);

      expect(samples[2].kind, HealthWorkoutKind.swimming);

      expect(samples[3].kind, HealthWorkoutKind.other);
    });

    test('filters invalid activity records', () async {
      final client = FakeHealthPluginClient(
        dataPoints: [
          _numericPoint(
            uuid: '',
            type: health_plugin.HealthDataType.STEPS,
            unit: health_plugin.HealthDataUnit.COUNT,
            value: 1000,
          ),
          _numericPoint(
            uuid: 'negative',
            type: health_plugin.HealthDataType.STEPS,
            unit: health_plugin.HealthDataUnit.COUNT,
            value: -50,
          ),
        ],
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final samples = await repository.readStepSamples(
        startTime: DateTime(2026, 8, 23),
        endTime: DateTime(2026, 8, 24),
      );

      expect(samples, isEmpty);
    });
  });
}

health_plugin.HealthDataPoint _numericPoint({
  required String uuid,
  required health_plugin.HealthDataType type,
  required health_plugin.HealthDataUnit unit,
  required num value,
}) {
  return health_plugin.HealthDataPoint(
    uuid: uuid,
    value: health_plugin.NumericHealthValue(numericValue: value),
    type: type,
    unit: unit,
    dateFrom: DateTime(2026, 8, 23, 8),
    dateTo: DateTime(2026, 8, 23, 9),
    sourcePlatform: health_plugin.HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'test-device',
    sourceId: 'test-source',
    sourceName: 'Test Health',
  );
}

health_plugin.HealthDataPoint _workoutPoint({
  required String uuid,
  required health_plugin.HealthWorkoutActivityType type,
}) {
  return health_plugin.HealthDataPoint(
    uuid: uuid,
    value: health_plugin.WorkoutHealthValue(workoutActivityType: type),
    type: health_plugin.HealthDataType.WORKOUT,
    unit: health_plugin.HealthDataUnit.NO_UNIT,
    dateFrom: DateTime(2026, 8, 23, 8),
    dateTo: DateTime(2026, 8, 23, 8, 45),
    sourcePlatform: health_plugin.HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'test-device',
    sourceId: 'test-source',
    sourceName: 'Test Health',
  );
}

class FakeHealthPluginClient implements HealthPluginClient {
  FakeHealthPluginClient({List<health_plugin.HealthDataPoint>? dataPoints})
    : dataPoints = dataPoints ?? <health_plugin.HealthDataPoint>[];

  final List<health_plugin.HealthDataPoint> dataPoints;

  @override
  Future<void> configure() async {}

  @override
  Future<health_plugin.HealthConnectSdkStatus?>
  getHealthConnectSdkStatus() async {
    return health_plugin.HealthConnectSdkStatus.sdkAvailable;
  }

  @override
  Future<bool?> hasPermissions(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) async {
    return true;
  }

  @override
  Future<bool> requestAuthorization(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) async {
    return true;
  }

  @override
  Future<List<health_plugin.HealthDataPoint>> getHealthDataFromTypes({
    required List<health_plugin.HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return dataPoints.where((point) => types.contains(point.type)).toList();
  }
}

class FakeActivityRecognitionPermission
    implements ActivityRecognitionPermission {
  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async => true;
}

class FakeHealthSettingsLauncher implements HealthSettingsLauncher {
  @override
  Future<void> openHealthSettings() async {}
}
