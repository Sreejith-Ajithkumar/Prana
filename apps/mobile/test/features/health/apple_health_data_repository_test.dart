import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health_plugin;

import 'package:mobile/features/health/data/clients/health_plugin_client.dart';
import 'package:mobile/features/health/data/repositories/apple_health_data_repository.dart';
import 'package:mobile/features/health/data/settings/health_settings_launcher.dart';
import 'package:mobile/features/health/data/storage/apple_health_authorization_store.dart';
import 'package:mobile/features/health/domain/entities/health_activity_sample.dart';
import 'package:mobile/features/health/domain/entities/health_data_type.dart';

void main() {
  group('AppleHealthDataRepository', () {
    test('reports Apple Health as available', () async {
      final client = FakeHealthPluginClient();
      final repository = _repository(client: client);

      final availability = await repository.checkAvailability();

      expect(availability.platform, HealthPlatform.appleHealth);
      expect(availability.isAvailable, isTrue);
      expect(client.configureCount, 1);

      await repository.checkAvailability();

      expect(client.configureCount, 1);
    });

    test('reports not requested before authorization flow', () async {
      final repository = _repository(
        client: FakeHealthPluginClient(),
        authorizationStore: FakeAppleHealthAuthorizationStore(),
      );

      final status = await repository.getAccessStatus(const {
        HealthDataType.steps,
      });

      expect(status, HealthAccessStatus.notRequested);
    });

    test('returns unknown after successful authorization without pretending '
        'read grants are knowable', () async {
      final authorizationStore = FakeAppleHealthAuthorizationStore();

      final client = FakeHealthPluginClient(requestAuthorizationResult: true);

      final repository = _repository(
        client: client,
        authorizationStore: authorizationStore,
      );

      final requestedStatus = await repository.requestAccess(const {
        HealthDataType.bodyWeight,
        HealthDataType.steps,
        HealthDataType.activeEnergyBurned,
        HealthDataType.workout,
      });

      expect(requestedStatus, HealthAccessStatus.unknown);
      expect(authorizationStore.requested, isTrue);

      final laterStatus = await repository.getAccessStatus(const {
        HealthDataType.steps,
      });

      expect(laterStatus, HealthAccessStatus.unknown);
      expect(
        client.lastRequestedTypes,
        containsAll(const {
          health_plugin.HealthDataType.WEIGHT,
          health_plugin.HealthDataType.STEPS,
          health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,
          health_plugin.HealthDataType.WORKOUT,
        }),
      );
    });

    test('maps Apple Health weight records', () async {
      final client = FakeHealthPluginClient(
        dataPoints: [
          _numericPoint(
            uuid: 'weight-1',
            type: health_plugin.HealthDataType.WEIGHT,
            unit: health_plugin.HealthDataUnit.KILOGRAM,
            value: 63.5,
          ),
        ],
      );

      final repository = _repository(client: client);

      final samples = await repository.readWeightSamples(
        startTime: DateTime(2026, 8, 1),
        endTime: DateTime(2026, 8, 25),
      );

      expect(samples, hasLength(1));
      expect(samples.single.externalId, 'weight-1');
      expect(samples.single.weightKg, 63.5);
      expect(samples.single.sourceName, 'Apple Health');
    });

    test('maps Apple Health activity records', () async {
      final client = FakeHealthPluginClient(
        dataPoints: [
          _numericPoint(
            uuid: 'steps-1',
            type: health_plugin.HealthDataType.STEPS,
            unit: health_plugin.HealthDataUnit.COUNT,
            value: 8123,
          ),
          _numericPoint(
            uuid: 'energy-1',
            type: health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,
            unit: health_plugin.HealthDataUnit.KILOCALORIE,
            value: 420.5,
          ),
          _workoutPoint(
            uuid: 'workout-1',
            type: health_plugin.HealthWorkoutActivityType.RUNNING,
          ),
        ],
      );

      final repository = _repository(client: client);

      final startTime = DateTime(2026, 8, 24);
      final endTime = DateTime(2026, 8, 25);

      final steps = await repository.readStepSamples(
        startTime: startTime,
        endTime: endTime,
      );

      final energy = await repository.readActiveEnergySamples(
        startTime: startTime,
        endTime: endTime,
      );

      final workouts = await repository.readWorkoutSamples(
        startTime: startTime,
        endTime: endTime,
      );

      expect(steps.single.steps, 8123);
      expect(energy.single.kilocalories, 420.5);
      expect(workouts.single.kind, HealthWorkoutKind.running);
      expect(workouts.single.duration, const Duration(hours: 1));
    });

    test('rejects invalid read ranges', () async {
      final repository = _repository(client: FakeHealthPluginClient());

      expect(
        () => repository.readStepSamples(
          startTime: DateTime(2026, 8, 24),
          endTime: DateTime(2026, 8, 24),
        ),
        throwsArgumentError,
      );
    });
  });
}

AppleHealthDataRepository _repository({
  required FakeHealthPluginClient client,
  FakeAppleHealthAuthorizationStore? authorizationStore,
}) {
  return AppleHealthDataRepository(
    healthClient: client,
    authorizationStore:
        authorizationStore ??
        FakeAppleHealthAuthorizationStore(requested: true),
    settingsLauncher: FakeHealthSettingsLauncher(),
  );
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
    dateFrom: DateTime(2026, 8, 24, 8),
    dateTo: DateTime(2026, 8, 24, 9),
    sourcePlatform: health_plugin.HealthPlatformType.appleHealth,
    sourceDeviceId: 'apple-watch',
    sourceId: 'com.apple.Health',
    sourceName: 'Apple Health',
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
    dateFrom: DateTime(2026, 8, 24, 7),
    dateTo: DateTime(2026, 8, 24, 8),
    sourcePlatform: health_plugin.HealthPlatformType.appleHealth,
    sourceDeviceId: 'apple-watch',
    sourceId: 'com.apple.Health',
    sourceName: 'Apple Health',
  );
}

class FakeHealthPluginClient implements HealthPluginClient {
  FakeHealthPluginClient({
    this.requestAuthorizationResult = true,
    this.dataPoints = const [],
  });

  final bool requestAuthorizationResult;
  final List<health_plugin.HealthDataPoint> dataPoints;

  int configureCount = 0;

  List<health_plugin.HealthDataType> lastRequestedTypes = const [];

  @override
  Future<void> configure() async {
    configureCount++;
  }

  @override
  Future<health_plugin.HealthConnectSdkStatus?>
  getHealthConnectSdkStatus() async {
    return null;
  }

  @override
  Future<bool?> hasPermissions(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) async {
    return null;
  }

  @override
  Future<bool> requestAuthorization(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) async {
    lastRequestedTypes = List.unmodifiable(types);
    return requestAuthorizationResult;
  }

  @override
  Future<List<health_plugin.HealthDataPoint>> getHealthDataFromTypes({
    required List<health_plugin.HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return dataPoints
        .where((point) => types.contains(point.type))
        .toList(growable: false);
  }
}

class FakeAppleHealthAuthorizationStore
    implements AppleHealthAuthorizationStore {
  FakeAppleHealthAuthorizationStore({this.requested = false});

  bool requested;

  @override
  Future<bool> hasRequestedAuthorization() async {
    return requested;
  }

  @override
  Future<void> markAuthorizationRequested() async {
    requested = true;
  }
}

class FakeHealthSettingsLauncher implements HealthSettingsLauncher {
  @override
  Future<void> openHealthSettings() async {}
}
