import 'package:health/health.dart' as health_plugin;

import '../../domain/entities/health_data_type.dart';
import '../../domain/entities/health_weight_sample.dart';
import '../../domain/repositories/health_data_repository.dart';
import '../clients/health_plugin_client.dart';
import '../mappers/health_plugin_type_mapper.dart';
import '../permissions/activity_recognition_permission.dart';
import '../settings/health_settings_launcher.dart';

class HealthConnectDataRepository implements HealthWeightDataRepository {
  HealthConnectDataRepository({
    HealthPluginClient? healthClient,
    this._mapper = const HealthPluginTypeMapper(),
    ActivityRecognitionPermission? activityRecognitionPermission,
    HealthSettingsLauncher? settingsLauncher,
  }) : _healthClient = healthClient ?? DefaultHealthPluginClient(),
       _activityRecognitionPermission =
           activityRecognitionPermission ??
           const PermissionHandlerActivityRecognitionPermission(),
       _settingsLauncher =
           settingsLauncher ?? const MethodChannelHealthSettingsLauncher();

  final HealthPluginClient _healthClient;
  final HealthPluginTypeMapper _mapper;
  final ActivityRecognitionPermission _activityRecognitionPermission;
  final HealthSettingsLauncher _settingsLauncher;

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }

    await _healthClient.configure();
    _configured = true;
  }

  @override
  Future<HealthAvailability> checkAvailability() async {
    await _ensureConfigured();

    final status = await _healthClient.getHealthConnectSdkStatus();

    return HealthAvailability(
      platform: HealthPlatform.healthConnect,
      isAvailable: status == health_plugin.HealthConnectSdkStatus.sdkAvailable,
    );
  }

  @override
  Future<HealthAccessStatus> getAccessStatus(
    Set<HealthDataType> dataTypes,
  ) async {
    if (dataTypes.isEmpty) {
      return HealthAccessStatus.granted;
    }

    final availability = await checkAvailability();

    if (!availability.isAvailable) {
      return HealthAccessStatus.unavailable;
    }

    var grantedCount = 0;

    for (final dataType in dataTypes) {
      final granted = await _hasReadAccess(dataType);

      if (granted) {
        grantedCount++;
      }
    }

    if (grantedCount == dataTypes.length) {
      return HealthAccessStatus.granted;
    }

    if (grantedCount > 0) {
      return HealthAccessStatus.partiallyGranted;
    }

    return HealthAccessStatus.denied;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    if (dataTypes.isEmpty) {
      return HealthAccessStatus.granted;
    }

    final availability = await checkAvailability();

    if (!availability.isAvailable) {
      return HealthAccessStatus.unavailable;
    }

    if (dataTypes.contains(HealthDataType.steps)) {
      await _activityRecognitionPermission.request();
    }

    final pluginTypes = _mapper.toPluginTypes(dataTypes);

    final permissions = List<health_plugin.HealthDataAccess>.filled(
      pluginTypes.length,
      health_plugin.HealthDataAccess.READ,
      growable: false,
    );

    await _healthClient.requestAuthorization(
      pluginTypes,
      permissions: permissions,
    );

    return getAccessStatus(dataTypes);
  }

  @override
  Future<List<HealthWeightSample>> readWeightSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!startTime.isBefore(endTime)) {
      throw ArgumentError('startTime must be before endTime.');
    }

    await _ensureConfigured();

    final dataPoints = await _healthClient.getHealthDataFromTypes(
      types: const [health_plugin.HealthDataType.WEIGHT],
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthWeightSample>[];

    for (final point in dataPoints) {
      if (point.type != health_plugin.HealthDataType.WEIGHT) {
        continue;
      }

      final value = point.value;

      if (value is! health_plugin.NumericHealthValue) {
        continue;
      }

      final weightKg = value.numericValue.toDouble();

      if (!weightKg.isFinite || weightKg <= 0) {
        continue;
      }

      final externalId = point.uuid.trim();

      if (externalId.isEmpty) {
        continue;
      }

      final sourceName = point.sourceName.trim();

      samples.add(
        HealthWeightSample(
          externalId: externalId,
          weightKg: weightKg,
          measuredAt: point.dateFrom,
          sourceName: sourceName.isEmpty ? null : sourceName,
        ),
      );
    }

    samples.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return samples;
  }

  Future<bool> _hasReadAccess(HealthDataType dataType) async {
    if (dataType == HealthDataType.steps) {
      final activityRecognitionGranted = await _activityRecognitionPermission
          .isGranted();

      if (!activityRecognitionGranted) {
        return false;
      }
    }

    final pluginType = _mapper.toPluginType(dataType);

    final granted = await _healthClient.hasPermissions(
      [pluginType],
      permissions: const [health_plugin.HealthDataAccess.READ],
    );

    return granted == true;
  }

  @override
  Future<void> openHealthSettings() {
    return _settingsLauncher.openHealthSettings();
  }
}
