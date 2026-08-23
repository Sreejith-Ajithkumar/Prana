import 'package:health/health.dart' as health_plugin;

import '../../domain/entities/health_activity_sample.dart';
import '../../domain/entities/health_data_type.dart';
import '../../domain/entities/health_weight_sample.dart';
import '../../domain/repositories/health_data_repository.dart';
import '../clients/health_plugin_client.dart';
import '../mappers/health_plugin_type_mapper.dart';
import '../permissions/activity_recognition_permission.dart';
import '../settings/health_settings_launcher.dart';

class HealthConnectDataRepository
    implements HealthWeightDataRepository, HealthActivityDataRepository {
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
    _validateTimeRange(startTime: startTime, endTime: endTime);

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

      samples.add(
        HealthWeightSample(
          externalId: externalId,
          weightKg: weightKg,
          measuredAt: point.dateFrom,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return samples;
  }

  @override
  Future<List<HealthStepsSample>> readStepSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    await _ensureConfigured();

    final dataPoints = await _healthClient.getHealthDataFromTypes(
      types: const [health_plugin.HealthDataType.STEPS],
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthStepsSample>[];

    for (final point in dataPoints) {
      if (point.type != health_plugin.HealthDataType.STEPS) {
        continue;
      }

      final value = point.value;

      if (value is! health_plugin.NumericHealthValue) {
        continue;
      }

      final numericSteps = value.numericValue.toDouble();

      if (!numericSteps.isFinite || numericSteps < 0) {
        continue;
      }

      final externalId = point.uuid.trim();

      if (externalId.isEmpty || point.dateTo.isBefore(point.dateFrom)) {
        continue;
      }

      samples.add(
        HealthStepsSample(
          externalId: externalId,
          steps: numericSteps.round(),
          startTime: point.dateFrom,
          endTime: point.dateTo,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.startTime.compareTo(b.startTime));

    return samples;
  }

  @override
  Future<List<HealthActiveEnergySample>> readActiveEnergySamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    await _ensureConfigured();

    final dataPoints = await _healthClient.getHealthDataFromTypes(
      types: const [health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthActiveEnergySample>[];

    for (final point in dataPoints) {
      if (point.type != health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED) {
        continue;
      }

      final value = point.value;

      if (value is! health_plugin.NumericHealthValue) {
        continue;
      }

      final kilocalories = value.numericValue.toDouble();

      if (!kilocalories.isFinite || kilocalories < 0) {
        continue;
      }

      final externalId = point.uuid.trim();

      if (externalId.isEmpty || point.dateTo.isBefore(point.dateFrom)) {
        continue;
      }

      samples.add(
        HealthActiveEnergySample(
          externalId: externalId,
          kilocalories: kilocalories,
          startTime: point.dateFrom,
          endTime: point.dateTo,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.startTime.compareTo(b.startTime));

    return samples;
  }

  @override
  Future<List<HealthWorkoutSample>> readWorkoutSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    await _ensureConfigured();

    final dataPoints = await _healthClient.getHealthDataFromTypes(
      types: const [health_plugin.HealthDataType.WORKOUT],
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthWorkoutSample>[];

    for (final point in dataPoints) {
      if (point.type != health_plugin.HealthDataType.WORKOUT) {
        continue;
      }

      final value = point.value;

      if (value is! health_plugin.WorkoutHealthValue) {
        continue;
      }

      final externalId = point.uuid.trim();

      if (externalId.isEmpty || !point.dateFrom.isBefore(point.dateTo)) {
        continue;
      }

      samples.add(
        HealthWorkoutSample(
          externalId: externalId,
          kind: _mapWorkoutKind(value.workoutActivityType),
          startTime: point.dateFrom,
          endTime: point.dateTo,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.startTime.compareTo(b.startTime));

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

  void _validateTimeRange({
    required DateTime startTime,
    required DateTime endTime,
  }) {
    if (!startTime.isBefore(endTime)) {
      throw ArgumentError('startTime must be before endTime.');
    }
  }

  String? _sourceName(health_plugin.HealthDataPoint point) {
    final value = point.sourceName.trim();

    return value.isEmpty ? null : value;
  }

  HealthWorkoutKind _mapWorkoutKind(
    health_plugin.HealthWorkoutActivityType type,
  ) {
    if (const {
      health_plugin.HealthWorkoutActivityType.WALKING,
      health_plugin.HealthWorkoutActivityType.WALKING_TREADMILL,
    }.contains(type)) {
      return HealthWorkoutKind.walking;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.RUNNING,
      health_plugin.HealthWorkoutActivityType.RUNNING_TREADMILL,
    }.contains(type)) {
      return HealthWorkoutKind.running;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.BIKING,
      health_plugin.HealthWorkoutActivityType.BIKING_STATIONARY,
      health_plugin.HealthWorkoutActivityType.HAND_CYCLING,
    }.contains(type)) {
      return HealthWorkoutKind.cycling;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.SWIMMING,
      health_plugin.HealthWorkoutActivityType.SWIMMING_OPEN_WATER,
      health_plugin.HealthWorkoutActivityType.SWIMMING_POOL,
    }.contains(type)) {
      return HealthWorkoutKind.swimming;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.STRENGTH_TRAINING,
      health_plugin.HealthWorkoutActivityType.WEIGHTLIFTING,
      health_plugin.HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
      health_plugin.HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
      health_plugin.HealthWorkoutActivityType.CALISTHENICS,
    }.contains(type)) {
      return HealthWorkoutKind.strengthTraining;
    }

    return HealthWorkoutKind.other;
  }

  @override
  Future<void> openHealthSettings() {
    return _settingsLauncher.openHealthSettings();
  }
}
