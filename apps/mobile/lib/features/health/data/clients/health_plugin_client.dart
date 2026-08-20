import 'package:health/health.dart' as health_plugin;

abstract interface class HealthPluginClient {
  Future<void> configure();

  Future<health_plugin.HealthConnectSdkStatus?> getHealthConnectSdkStatus();

  Future<bool?> hasPermissions(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  });

  Future<bool> requestAuthorization(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  });

  Future<List<health_plugin.HealthDataPoint>> getHealthDataFromTypes({
    required List<health_plugin.HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  });
}

class DefaultHealthPluginClient implements HealthPluginClient {
  DefaultHealthPluginClient({health_plugin.Health? health})
    : _health = health ?? health_plugin.Health();

  final health_plugin.Health _health;

  @override
  Future<void> configure() {
    return _health.configure();
  }

  @override
  Future<health_plugin.HealthConnectSdkStatus?> getHealthConnectSdkStatus() {
    return _health.getHealthConnectSdkStatus();
  }

  @override
  Future<bool?> hasPermissions(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) {
    return _health.hasPermissions(types, permissions: permissions);
  }

  @override
  Future<bool> requestAuthorization(
    List<health_plugin.HealthDataType> types, {
    required List<health_plugin.HealthDataAccess> permissions,
  }) {
    return _health.requestAuthorization(types, permissions: permissions);
  }

  @override
  Future<List<health_plugin.HealthDataPoint>> getHealthDataFromTypes({
    required List<health_plugin.HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return _health.getHealthDataFromTypes(
      types: types,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
