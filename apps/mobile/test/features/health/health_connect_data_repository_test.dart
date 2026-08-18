import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health_plugin;

import 'package:mobile/features/health/data/clients/health_plugin_client.dart';
import 'package:mobile/features/health/data/permissions/activity_recognition_permission.dart';
import 'package:mobile/features/health/data/repositories/health_connect_data_repository.dart';
import 'package:mobile/features/health/data/settings/health_settings_launcher.dart';
import 'package:mobile/features/health/domain/entities/health_data_type.dart';

void main() {
  group('HealthConnectDataRepository', () {
    test('reports Health Connect as available', () async {
      final client = FakeHealthPluginClient(
        sdkStatus: health_plugin.HealthConnectSdkStatus.sdkAvailable,
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final availability = await repository.checkAvailability();

      expect(availability.platform, HealthPlatform.healthConnect);
      expect(availability.isAvailable, isTrue);
      expect(client.configureCalls, 1);
    });

    test('reports Health Connect as unavailable', () async {
      final client = FakeHealthPluginClient(
        sdkStatus: health_plugin.HealthConnectSdkStatus.sdkUnavailable,
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final availability = await repository.checkAvailability();

      expect(availability.isAvailable, isFalse);
    });

    test('reports granted when all requested access exists', () async {
      final client = FakeHealthPluginClient(
        grantedTypes: {
          health_plugin.HealthDataType.WEIGHT,
          health_plugin.HealthDataType.STEPS,
        },
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(
          granted: true,
        ),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final status = await repository.getAccessStatus({
        HealthDataType.bodyWeight,
        HealthDataType.steps,
      });

      expect(status, HealthAccessStatus.granted);
    });

    test('reports partially granted access', () async {
      final client = FakeHealthPluginClient(
        grantedTypes: {health_plugin.HealthDataType.WEIGHT},
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: FakeActivityRecognitionPermission(
          granted: true,
        ),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final status = await repository.getAccessStatus({
        HealthDataType.bodyWeight,
        HealthDataType.steps,
      });

      expect(status, HealthAccessStatus.partiallyGranted);
    });

    test('reports denied when no requested access exists', () async {
      final repository = HealthConnectDataRepository(
        healthClient: FakeHealthPluginClient(),
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final status = await repository.getAccessStatus({
        HealthDataType.bodyWeight,
      });

      expect(status, HealthAccessStatus.denied);
    });

    test('requests activity recognition when requesting steps', () async {
      final client = FakeHealthPluginClient(grantRequestedTypes: true);

      final activityPermission = FakeActivityRecognitionPermission(
        grantOnRequest: true,
      );

      final repository = HealthConnectDataRepository(
        healthClient: client,
        activityRecognitionPermission: activityPermission,
        settingsLauncher: FakeHealthSettingsLauncher(),
      );

      final status = await repository.requestAccess({HealthDataType.steps});

      expect(activityPermission.requestCalls, 1);
      expect(client.requestAuthorizationCalls, 1);
      expect(status, HealthAccessStatus.granted);
    });

    test('opens health settings through launcher', () async {
      final launcher = FakeHealthSettingsLauncher();

      final repository = HealthConnectDataRepository(
        healthClient: FakeHealthPluginClient(),
        activityRecognitionPermission: FakeActivityRecognitionPermission(),
        settingsLauncher: launcher,
      );

      await repository.openHealthSettings();

      expect(launcher.openCalls, 1);
    });
  });
}

class FakeHealthPluginClient implements HealthPluginClient {
  FakeHealthPluginClient({
    this.sdkStatus = health_plugin.HealthConnectSdkStatus.sdkAvailable,
    Set<health_plugin.HealthDataType>? grantedTypes,
    this.grantRequestedTypes = false,
  }) : grantedTypes = grantedTypes ?? <health_plugin.HealthDataType>{};

  final health_plugin.HealthConnectSdkStatus? sdkStatus;
  final Set<health_plugin.HealthDataType> grantedTypes;
  final bool grantRequestedTypes;

  int configureCalls = 0;
  int requestAuthorizationCalls = 0;

  @override
  Future<void> configure() async {
    configureCalls++;
  }

  @override
  Future<health_plugin.HealthConnectSdkStatus?>
  getHealthConnectSdkStatus() async {
    return sdkStatus;
  }

  @override
  Future<bool?> hasPermissions(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) async {
    return types.every(grantedTypes.contains);
  }

  @override
  Future<bool> requestAuthorization(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) async {
    requestAuthorizationCalls++;

    if (grantRequestedTypes) {
      grantedTypes.addAll(types);
    }

    return grantRequestedTypes;
  }
}

class FakeActivityRecognitionPermission
    implements ActivityRecognitionPermission {
  FakeActivityRecognitionPermission({
    this.granted = false,
    this.grantOnRequest = false,
  });

  bool granted;
  final bool grantOnRequest;

  int requestCalls = 0;

  @override
  Future<bool> isGranted() async {
    return granted;
  }

  @override
  Future<bool> request() async {
    requestCalls++;

    if (grantOnRequest) {
      granted = true;
    }

    return granted;
  }
}

class FakeHealthSettingsLauncher implements HealthSettingsLauncher {
  int openCalls = 0;

  @override
  Future<void> openHealthSettings() async {
    openCalls++;
  }
}
